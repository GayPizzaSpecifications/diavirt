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

    @Flag(name: .long, help: "Enable Passing of Signals to VM")
    var enableSignalPassing: Bool = false

    func run() throws {
        let configFileURL = URL(fileURLWithPath: configFilePath)
        let data = try Data(contentsOf: configFileURL)
        let decoder = JSONDecoder()
        let configuration = try decoder.decode(DAVirtualMachineConfiguration.self, from: data)
        Global.machine = DAVirtualMachine(configuration, enableWireProtocol: wireProtocol)
        try Global.machine!.create()
        Global.stateObserverHandle = Global.machine!.watchForState { state in
            if state == .error {
                DiavirtCommand.exit(withError: ExitCode.failure)
            } else if state == .stopped {
                DiavirtCommand.exit(withError: ExitCode.success)
            }
        }

        Global.enableSignalPassing = enableSignalPassing

        atexit {
            Global.terminalMode.restoreOriginalAttributes()
            Global.stateObserverHandle?.invalidate()
        }

        signal(SIGINT) { _ in
            if Global.enableSignalPassing {
                Global.machine?.writeStdinDataSafe(Data(base64Encoded: "Aw==")!)
            } else {
                Global.machine?.writeProtocolEvent(SimpleEvent(type: "killed"))
                DispatchQueue.main.async {
                    DiavirtCommand.exit(withError: ExitCode.success)
                }
            }
        }

        if enableSignalPassing {
            signal(SIGSTOP) { _ in
                Global.machine?.writeStdinDataSafe(Data(base64Encoded: "Gg==")!)
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
        static var stateObserverHandle: NSKeyValueObservation?
        static var enableSignalPassing = false
        static var terminalMode = TerminalMode()
    }
}
