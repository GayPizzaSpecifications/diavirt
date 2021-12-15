//
//  Runtime.swift
//  diavirt
//
//  Created by Kenneth Endfinger on 12/13/21.
//

import Foundation
import Virtualization

class DAVirtualMachine: NSObject, VZVirtualMachineDelegate {
    let configuration: DAVirtualMachineConfiguration
    let enableWireProtocol: Bool

    var machine: VZVirtualMachine?

    init(_ configuration: DAVirtualMachineConfiguration, enableWireProtocol: Bool) {
        self.configuration = configuration
        self.enableWireProtocol = enableWireProtocol
    }

    func create() throws {
        let config = try configuration.build()
        try config.validate()
        let machine = VZVirtualMachine(configuration: config)
        machine.delegate = self
        self.machine = machine
    }

    func start() {
        machine!.start { result in
            switch result {
            case .success:
                self.writeProtocolMessage(SimpleEvent(type: "started"))
            case let .failure(error):
                self.writeProtocolMessage(ErrorEvent(error))
            }
        }
    }

    func watchForState(stateHandler: @escaping (VZVirtualMachine.State) -> Void) -> NSKeyValueObservation {
        machine!.observe(\.state) { machine, _ in
            let state = machine.state
            self.writeProtocolMessage(StateEvent(self.stateToString(state)))
            stateHandler(state)
        }
    }

    func guestDidStop(_: VZVirtualMachine) {
        writeProtocolMessage(SimpleEvent(type: "guest-stopped"))
    }

    func virtualMachine(_: VZVirtualMachine, didStopWithError error: Error) {
        writeProtocolMessage(ErrorEvent(error))
    }

    func stop() throws {
        try machine?.requestStop()
    }

    func writeProtocolMessage<T: Codable>(_ event: T) {
        if !enableWireProtocol {
            return
        }

        var data = try! encoder.encode(event)
        data.append(0x0A)
        DispatchQueue.main.async {
            try! FileHandle.standardError.write(contentsOf: data)
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
