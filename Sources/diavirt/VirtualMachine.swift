//
//  Runtime.swift
//  diavirt
//
//  Created by Alex Zenla on 12/13/21.
//

import Foundation
import Virtualization

class DAVirtualMachine: NSObject, WireProtocol, VZVirtualMachineDelegate {
    let configuration: DAVirtualMachineConfiguration
    let enableWireProtocol: Bool

    #if arch(arm64)
    let enableInstallerMode: Bool
    let autoInstallerMode: Bool
    #endif

    var machine: VZVirtualMachine?
    var state: DABuildState?
    var inputs: [String: Pipe] = [:]
    var outputs: [String: Pipe] = [:]
    var diskAllocatedStates: [Bool] = []

    var inhibitStopForRestart = false

    #if arch(arm64)
    init(_ configuration: DAVirtualMachineConfiguration, enableWireProtocol: Bool, enableInstallerMode: Bool, autoInstallerMode: Bool) {
        self.configuration = configuration
        self.enableWireProtocol = enableWireProtocol
        self.enableInstallerMode = enableInstallerMode
        self.autoInstallerMode = autoInstallerMode
    }
    #else
    init(_ configuration: DAVirtualMachineConfiguration, enableWireProtocol: Bool) {
        self.configuration = configuration
        self.enableWireProtocol = enableWireProtocol
    }
    #endif

    func create() async throws {
        writeProtocolEvent(StateEvent("create.start"))
        writeProtocolEvent(StateEvent("preflight.start"))
        state = try await configuration.preflight(wire: self)
        writeProtocolEvent(StateEvent("preflight.end"))
        writeProtocolEvent(StateEvent("configure.start"))
        let config = try configuration.build(wire: self, state: state!)
        writeProtocolEvent(StateEvent("configure.end"))
        let machine = VZVirtualMachine(configuration: config)
        machine.delegate = self
        self.machine = machine
        writeProtocolEvent(StateEvent("create.end"))
    }

    func start() {
        writeProtocolEvent(StateEvent("runtime.starting"))

        #if arch(arm64)
        var shouldInstallerMode = enableInstallerMode
        if autoInstallerMode {
            if !diskAllocatedStates.isEmpty,
               diskAllocatedStates.filter({ $0 }).count == diskAllocatedStates.count
            {
                shouldInstallerMode = true
                writeProtocolEvent(NotifyEvent("runtime.installer.auto"))
            }
        }

        if shouldInstallerMode {
            doInstallMode()
            return
        }
        #endif
        doActualStart()
    }

    #if arch(arm64)
    private func doInstallMode() {
        DispatchQueue.main.async {
            let installer = VZMacOSInstaller(virtualMachine: self.machine!, restoringFromImageAt: self.state!.macRestoreImage!.url)
            self.writeProtocolEvent(StateEvent("runtime.installer.start"))
            installer.install(completionHandler: self.onInstallComplete)
            self.observeInstallProgress(installer: installer)
        }
    }

    private func observeInstallProgress(installer: VZMacOSInstaller) {
        DiavirtCommand.Global.installationObserver = installer.progress.observe(\.fractionCompleted, options: [.initial, .new]) { _, change in
            self.writeProtocolEvent(InstallationProgressEvent(progress: change.newValue! * 100.0))
        }
    }

    private func onInstallComplete(result: Result<Void, Error>) {
        writeProtocolEvent(StateEvent("runtime.installer.end"))
        switch result {
        case let .failure(error):
            writeProtocolEvent(ErrorEvent(error))
        case .success:
            inhibitStopForRestart = true
            writeProtocolEvent(StateEvent("runtime.started"))
        }
    }
    #endif

    private func doActualStart() {
        DispatchQueue.main.async {
            let options = self.configuration.startOptions?.build()
            if let options {
                self.machine?.start(options: options, completionHandler: self.onMachineStartWithOptions)
            } else {
                self.machine?.start(completionHandler: self.onMachineStart)
            }
        }
    }

    private func onMachineStart(result: Result<Void, Error>) {
        switch result {
        case .success:
            writeProtocolEvent(SimpleEvent(type: "started"))
        case let .failure(error):
            writeProtocolEvent(ErrorEvent(error))
        }
    }
    
    private func onMachineStartWithOptions(error: Error?) {
        if let error {
            onMachineStart(result: .failure(error))
        } else {
            onMachineStart(result: .success(()))
        }
    }

    func watchForState(stateHandler: @escaping (VZVirtualMachine.State) -> Void) -> NSKeyValueObservation {
        machine!.observe(\.state) { machine, _ in
            let state = machine.state
            self.writeProtocolEvent(StateEvent(self.stateToString(state)))
            if state == .stopped, self.inhibitStopForRestart {
                self.inhibitStopForRestart = false
                self.doActualStart()
                return
            }
            stateHandler(state)
        }
    }

    func trackInputPipe(_ pipe: Pipe, tag: String) {
        inputs[tag] = pipe
    }

    func trackOutputPipe(_ pipe: Pipe, tag: String) {
        outputs[tag] = pipe
    }

    func trackDiskAllocated(allocated: Bool) {
        diskAllocatedStates.append(allocated)
    }

    func guestDidStop(_: VZVirtualMachine) {
        writeProtocolEvent(SimpleEvent(type: "guest-stopped"))
    }

    func virtualMachine(_: VZVirtualMachine, didStopWithError error: Error) {
        writeProtocolEvent(ErrorEvent(error))
    }

    func stop() throws {
        try machine?.requestStop()
    }

    func writeProtocolEvent<T>(_ event: T) where T: WireEvent {
        if !enableWireProtocol {
            if let message = event.toUserMessage() {
                var data = message.data(using: .utf8)!
                data.append(0x0A)
                DispatchQueue.main.async {
                    try! FileHandle.standardError.write(contentsOf: data)
                }
            }

            return
        }

        var data = try! encoder.encode(event)
        data.append(0x0A)
        DispatchQueue.main.async {
            try! FileHandle.standardError.write(contentsOf: data)
        }
    }

    func writeStdinDataSafe(_ data: Data) {
        if let maybeStdinPipe = outputs["stdin"] {
            do {
                try maybeStdinPipe.fileHandleForWriting.write(contentsOf: data)
            } catch {
                writeProtocolEvent(ErrorEvent(error))
            }
        }
    }

    func stateToString(_ state: VZVirtualMachine.State) -> String {
        switch state {
        case .stopped:
            return "stopped"
        case .running:
            return "running"
        case .paused:
            return "paused"
        case .error:
            return "error"
        case .starting:
            return "starting"
        case .pausing:
            return "pausing"
        case .resuming:
            return "resuming"
        case .stopping:
            return "stopping"
        case .saving:
            return "saving"
        case .restoring:
            return "restoring"
        @unknown default:
            return "unknown"
        }
    }

    private let encoder = JSONEncoder()
}
