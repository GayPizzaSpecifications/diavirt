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
    var machine: VZVirtualMachine?

    init(_ configuration: DAVirtualMachineConfiguration) {
        self.configuration = configuration
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
                self.write(SimpleEvent(type: "started"))
            case let .failure(error):
                self.write(ErrorEvent(error))
            }
        }
    }

    func watchForState(stateHandler: @escaping (VZVirtualMachine.State) -> Void) -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
        timer.schedule(deadline: .now(), repeating: .milliseconds(10))

        var lastMachineState: VZVirtualMachine.State = .stopped
        timer.setEventHandler {
            guard let machine = self.machine else {
                return
            }
            let currentState = machine.state
            if currentState != lastMachineState {
                self.write(StateEvent(self.stateToString(currentState)))
                stateHandler(currentState)
                lastMachineState = currentState
            }
        }
        timer.resume()
        return timer
    }

    func guestDidStop(_: VZVirtualMachine) {}

    func virtualMachine(_: VZVirtualMachine, didStopWithError _: Error) {}

    func stop() throws {
        try machine?.requestStop()
    }

    func write<T: Codable>(_ event: T) {
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
