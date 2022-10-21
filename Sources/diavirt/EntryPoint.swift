//
//  main.swift
//  diavirt
//
//  Created by Alex Zenla on 12/13/21.
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

    @Flag(name: .long, inversion: .prefixedEnableDisable, help: "Enable Terminal Raw Mode")
    var rawMode: Bool = true

    #if arch(arm64)
    @Flag(name: .long, inversion: .prefixedEnableDisable, help: "Enable Installer Mode")
    var installerMode: Bool = false

    @Flag(name: [
        .customShort("i"),
        .long
    ], inversion: .prefixedEnableDisable, help: "Enable Automatic Installer Mode")
    var autoInstallerMode: Bool = true

    @Flag(name: [
        .customShort("m"),
        .long
    ])
    var cannedMac: Bool = false
    #endif

    func run() throws {
        let configFileURL = URL(fileURLWithPath: configFilePath)

        var shouldEnableSignalPassing = enableSignalPassing
        var shouldRawMode = rawMode
        var shouldViewerMode = viewerMode

        #if arch(arm64)
        if cannedMac {
            shouldEnableSignalPassing = false
            shouldRawMode = false
            shouldViewerMode = true

            if !FileManager.default.fileExists(atPath: configFileURL.path) {
                try FileManager.default.createDirectory(at: configFileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                let canned = createCannedMac()
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let encoded = try encoder.encode(canned)
                try encoded.write(to: configFileURL)
            }
        }
        #endif

        let data = try Data(contentsOf: configFileURL)
        let decoder = JSONDecoder()
        let configuration = try decoder.decode(DAVirtualMachineConfiguration.self, from: data)

        #if arch(arm64)
        Global.machine = DAVirtualMachine(configuration, enableWireProtocol: wireProtocol, enableInstallerMode: installerMode, autoInstallerMode: autoInstallerMode)
        #else
        Global.machine = DAVirtualMachine(configuration, enableWireProtocol: wireProtocol)
        #endif

        Global.enableSignalPassing = shouldEnableSignalPassing

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

        if shouldEnableSignalPassing {
            signal(SIGSTOP) { _ in
                Global.machine?.writeStdinDataSafe(Data(base64Encoded: "Gg==")!)
            }
        }

        if shouldRawMode {
            Global.terminalMode.enableRawMode()
        }

        Task {
            try await Global.machine!.create()
            Global.machine?.start()
            Global.stateObserverHandle = Global.machine!.watchForState { state in
                Task {
                    if state == .error {
                        DiavirtCommand.exit(withError: ExitCode.failure)
                    } else if state == .stopped {
                        DiavirtCommand.exit(withError: ExitCode.success)
                    }
                }
            }
        }

        if shouldViewerMode {
            NSApplication.shared.setActivationPolicy(.regular)
            DiavirtApp.main()
        }

        dispatchMain()
    }

    enum Global {
        static var machine: DAVirtualMachine?
        static var stateObserverHandle: NSKeyValueObservation?
        static var installationObserver: NSKeyValueObservation?
        static var enableSignalPassing = false
        static var terminalMode = TerminalMode()
    }
}
