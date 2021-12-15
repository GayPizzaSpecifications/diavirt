//
//  main.swift
//  diavirt
//
//  Created by Kenneth Endfinger on 12/13/21.
//

import ArgumentParser
import Foundation
import Virtualization

@main
struct DiavirtCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "diavirt",
        abstract: "Virtualization for macOS"
    )

    @Option(name: .shortAndLong, help: "Configuration File Path")
    var configFilePath: String = "vm.json"

    @Flag(name: .shortAndLong, help: "Enable Viewer Mode")
    var viewerMode: Bool = false

    @Flag(name: .shortAndLong, help: "Enable Wire Protocol")
    var wireProtocol: Bool = false

    func run() throws {
        let configFileURL = URL(fileURLWithPath: configFilePath)
        let data = try Data(contentsOf: configFileURL)
        let decoder = JSONDecoder()
        let configuration = try decoder.decode(DAVirtualMachineConfiguration.self, from: data)
        Global.machine = DAVirtualMachine(configuration, enableWireProtocol: wireProtocol)
        try Global.machine!.create()
        Global.stateTimerHandle = Global.machine!.watchForState { state in
            if state == .error {
                DiavirtCommand.exit(withError: ExitCode.failure)
            } else if state == .stopped {
                DiavirtCommand.exit(withError: ExitCode.success)
            }
        }

        atexit {
            Global.stateTimerHandle?.cancel()
        }

        signal(SIGINT) { _ in
            Global.machine!.writeProtocolMessage(SimpleEvent(type: "killed"))
            DispatchQueue.main.async {
                DiavirtCommand.exit(withError: ExitCode.success)
            }
        }

        DispatchQueue.main.async {
            Global.machine?.start()
        }

        if viewerMode {
            NSApplication.shared.setActivationPolicy(.regular)
            DiavirtApp.main()
        }
        dispatchMain()
    }

    enum Global {
        static var machine: DAVirtualMachine?
        static var stateTimerHandle: DispatchSourceTimer?
    }
}
