//
//  ConfigurationModel.swift
//  diavirt
//
//  Created by Kenneth Endfinger on 12/13/21.
//

import Foundation
import Virtualization

struct DAVirtualMachineConfiguration: Codable {
    let cpuCoreCount: Int
    let memorySizeInBytes: UInt64
    let bootLoader: DABootLoader
    let storageDevices: [DAStorageDevice]?
    let serialPorts: [DASerialPort]?
    let entropyDevices: [DAEntropyDevice]?
    let memoryBalloonDevices: [DAMemoryBalloonDevice]?
    let networkDevices: [DANetworkDevice]?
    let graphicsDevices: [DAGraphicsDevice]?
}

struct DABootLoader: Codable {
    let linuxBootLoader: DALinuxBootLoader?
}

struct DALinuxBootLoader: Codable {
    let kernelFilePath: String
    let initialRamdiskPath: String?
    let commandLine: String?
}

struct DAStorageDevice: Codable {
    let diskImageAttachment: DADiskImageAttachment?
    let virtioBlockDevice: DAVirtioBlockDevice?
}

struct DADiskImageAttachment: Codable {
    let imageFilePath: String
    let isReadOnly: Bool?
}

struct DAVirtioBlockDevice: Codable {}

struct DASerialPort: Codable {
    let stdioSerialAttachment: DAStdioSerialAttachment?
    let virtioConsoleDevice: DAVirtioConsoleDevice?
}

struct DAStdioSerialAttachment: Codable {}

struct DAVirtioConsoleDevice: Codable {}

struct DAEntropyDevice: Codable {
    let virtioEntropyDevice: DAVirtioEntropyDevice?
}

struct DAVirtioEntropyDevice: Codable {}

struct DAMemoryBalloonDevice: Codable {
    let virtioTraditionalMemoryBalloonDevice: DAVirtioTraditionalMemoryBalloonDevice?
}

struct DAVirtioTraditionalMemoryBalloonDevice: Codable {}

struct DANetworkDevice: Codable {
    let virtioNetworkDevice: DAVirtioNetworkDevice?
    let natNetworkAttachment: DANATNetworkAttachment?
}

struct DAVirtioNetworkDevice: Codable {
    let macAddress: String?
}

struct DANATNetworkAttachment: Codable {}

struct DAGraphicsDevice: Codable {
    let macGraphicsDevice: DAMacGraphicsDevice?
}

struct DAMacGraphicsDevice: Codable {
    let displays: [DAMacGraphicsDisplay]
}

struct DAMacGraphicsDisplay: Codable {
    let widthInPixels: Int
    let heightInPixels: Int
    let pixelsPerInch: Int
}
