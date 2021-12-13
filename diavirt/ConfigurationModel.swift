//
//  ConfigurationModel.swift
//  diavirt
//
//  Created by Kenneth Endfinger on 12/13/21.
//

import Foundation
import Virtualization

struct DALinuxBootLoader: Codable {
    let kernelFilePath: String
    let initialRamdiskPath: String?
    let commandLine: String?

    func build() -> VZLinuxBootLoader {
        let bootloader = VZLinuxBootLoader(kernelURL: URL(fileURLWithPath: kernelFilePath).absoluteURL)

        if let initialRamdiskPath = initialRamdiskPath {
            bootloader.initialRamdiskURL = URL(fileURLWithPath: initialRamdiskPath).absoluteURL
        }

        if let commandLine = commandLine {
            bootloader.commandLine = commandLine
        }

        return bootloader
    }
}

struct DABootLoader: Codable {
    let linux: DALinuxBootLoader?

    func apply(to configuration: VZVirtualMachineConfiguration) throws {
        if let linux = linux {
            configuration.bootLoader = linux.build()
        }
    }
}

struct DADiskImageAttachment: Codable {
    let imageFilePath: String
    let isReadOnly: Bool?

    func build() throws -> VZDiskImageStorageDeviceAttachment {
        let url = URL(fileURLWithPath: imageFilePath)
        return try VZDiskImageStorageDeviceAttachment(url: url.absoluteURL, readOnly: isReadOnly ?? false)
    }
}

struct DAVirtioBlockDevice: Codable {
    func build(attachment: VZStorageDeviceAttachment) throws -> VZStorageDeviceConfiguration {
        VZVirtioBlockDeviceConfiguration(attachment: attachment)
    }
}

struct DAStorageDevice: Codable {
    let diskImageAttachment: DADiskImageAttachment?
    let virtioBlockDevice: DAVirtioBlockDevice?

    func build() throws -> VZStorageDeviceConfiguration {
        var storage: VZStorageDeviceConfiguration?
        var attachment: VZStorageDeviceAttachment?

        if let diskImageAttachment = diskImageAttachment {
            attachment = try diskImageAttachment.build()
        }

        if let virtioBlockDevice = virtioBlockDevice {
            storage = try virtioBlockDevice.build(attachment: attachment!)
        }

        return storage!
    }
}

struct DAVirtioConsoleDevice: Codable {
    func build() throws -> VZVirtioConsoleDeviceSerialPortConfiguration {
        VZVirtioConsoleDeviceSerialPortConfiguration()
    }
}

struct DAStdioSerialAttachment: Codable {
    func build() throws -> VZFileHandleSerialPortAttachment {
        VZFileHandleSerialPortAttachment(fileHandleForReading: FileHandle.standardInput, fileHandleForWriting: FileHandle.standardOutput)
    }
}

struct DASerialPort: Codable {
    let stdioSerialAttachment: DAStdioSerialAttachment?
    let virtioConsoleDevice: DAVirtioConsoleDevice?

    func build() throws -> VZSerialPortConfiguration {
        var port: VZSerialPortConfiguration?
        var attachment: VZSerialPortAttachment?

        if let stdioSerialAttachment = stdioSerialAttachment {
            attachment = try stdioSerialAttachment.build()
        }

        if let virtioConsoleDevice = virtioConsoleDevice {
            port = try virtioConsoleDevice.build()
        }

        port?.attachment = attachment!
        return port!
    }
}

struct DAVirtioEntropyDevice: Codable {
    func build() throws -> VZVirtioEntropyDeviceConfiguration {
        VZVirtioEntropyDeviceConfiguration()
    }
}

struct DAEntropyDevice: Codable {
    let virtioEntropyDevice: DAVirtioEntropyDevice?

    func build() throws -> VZEntropyDeviceConfiguration? {
        if let virtioEntropyDevice = virtioEntropyDevice {
            return try virtioEntropyDevice.build()
        }
        return nil
    }
}

struct DAVirtualMachineConfiguration: Codable {
    let bootloader: DABootLoader
    let cpuCoreCount: Int
    let memorySizeInBytes: UInt64
    var storageDevices: [DAStorageDevice] = []
    var serialPorts: [DASerialPort] = []
    var entropyDevices: [DAEntropyDevice] = []

    func build() throws -> VZVirtualMachineConfiguration {
        let configuration = VZVirtualMachineConfiguration()
        try bootloader.apply(to: configuration)
        configuration.cpuCount = cpuCoreCount
        configuration.memorySize = memorySizeInBytes

        for storageDevice in storageDevices {
            configuration.storageDevices.append(try storageDevice.build())
        }

        for serialPort in serialPorts {
            configuration.serialPorts.append(try serialPort.build())
        }

        for entropyDevice in entropyDevices {
            configuration.entropyDevices.append(try entropyDevice.build()!)
        }

        return configuration
    }
}
