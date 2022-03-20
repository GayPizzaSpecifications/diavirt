//
//  Runtime.swift
//  diavirt
//
//  Created by Kenneth Endfinger on 12/13/21.
//

import Foundation
import Virtualization

class DAVirtualMachine: NSObject, WireProtocol, VZVirtualMachineDelegate {
    let configuration: DAVirtualMachineConfiguration
    let enableWireProtocol: Bool
    let enableInstallerMode: Bool

    var machine: VZVirtualMachine?
    var state: DABuildState?
    var inputs: [String: Pipe] = [:]
    var outputs: [String: Pipe] = [:]

    init(_ configuration: DAVirtualMachineConfiguration, enableWireProtocol: Bool, enableInstallerMode: Bool) {
        self.configuration = configuration
        self.enableWireProtocol = enableWireProtocol
        self.enableInstallerMode = enableInstallerMode
    }

    func create() async throws {
        writeProtocolEvent(StateEvent("create.start"))
        writeProtocolEvent(StateEvent("preflight.start"))
        state = try await configuration.preflight(wire: self)
        writeProtocolEvent(StateEvent("preflight.end"))
        writeProtocolEvent(StateEvent("configure.start"))
        let config = try configuration.build(wire: self, state: state!)
        try config.validate()
        writeProtocolEvent(StateEvent("configure.end"))
        let machine = VZVirtualMachine(configuration: config)
        machine.delegate = self
        self.machine = machine
        writeProtocolEvent(StateEvent("create.end"))
    }

    func start() {
        if enableInstallerMode {
            doInstallMode()
        } else {
            writeProtocolEvent(StateEvent("runtime.starting"))
            doActualStart()
            writeProtocolEvent(StateEvent("runtime.started"))
        }
    }

    #if arch(arm64)
        private func doInstallMode() {
            DispatchQueue.main.async {
                let installer = VZMacOSInstaller(virtualMachine: self.machine!, restoringFromImageAt: self.state!.macRestoreImage!.url)
                installer.install { result in
                    switch result {
                    case let .failure(error):
                        self.writeProtocolEvent(ErrorEvent(error))
                    case .success:
                        self.doActualStart()
                        self.writeProtocolEvent(StateEvent("runtime.started"))
                    }
                }
                DiavirtCommand.Global.installationObserver = installer.progress.observe(\.fractionCompleted, options: [.initial, .new]) { _, change in
                    NSLog("Installation progress: \(change.newValue! * 100).")
                }
            }
        }
    #else
        private func doInstallMode() {}
    #endif

    private func doActualStart() {
        DispatchQueue.main.async {
            self.machine?.start { result in
                switch result {
                case .success:
                    self.writeProtocolEvent(SimpleEvent(type: "started"))
                case let .failure(error):
                    self.writeProtocolEvent(ErrorEvent(error))
                }
            }
        }
    }

    func watchForState(stateHandler: @escaping (VZVirtualMachine.State) -> Void) -> NSKeyValueObservation {
        machine!.observe(\.state) { machine, _ in
            let state = machine.state
            self.writeProtocolEvent(StateEvent(self.stateToString(state)))
            stateHandler(state)
        }
    }

    func trackInputPipe(_ pipe: Pipe, tag: String) {
        inputs[tag] = pipe
    }

    func trackOutputPipe(_ pipe: Pipe, tag: String) {
        outputs[tag] = pipe
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

    private let encoder = JSONEncoder()

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
        @unknown default:
            return "unknown"
        }
    }
}
