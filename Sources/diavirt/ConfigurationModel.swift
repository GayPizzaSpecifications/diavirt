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
    let platform: DAPlatform
    let storageDevices: [DAStorageDevice]?
    let serialPorts: [DASerialPort]?
    let entropyDevices: [DAEntropyDevice]?
    let memoryBalloonDevices: [DAMemoryBalloonDevice]?
    let networkDevices: [DANetworkDevice]?
    let graphicsDevices: [DAGraphicsDevice]?
    let directorySharingDevices: [DADirectorySharingDevice]?
}

struct DABootLoader: Codable {
    let linuxBootLoader: DALinuxBootLoader?
}

struct DALinuxBootLoader: Codable {
    let kernelFilePath: String
    let initialRamdiskPath: String?
    let commandLine: String?
}

struct DAPlatform: Codable {
    let genericPlatform: DAGenericPlatform?
}

struct DAGenericPlatform: Codable {}

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
    let wireSerialAttachment: DAWireSerialAttachment?
    let virtioConsoleDevice: DAVirtioConsoleDevice?
}

struct DAStdioSerialAttachment: Codable {}

struct DAWireSerialAttachment: Codable {
    let tag: String
}

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

struct DADirectorySharingDevice: Codable {
    let virtioFileSystemDevice: DAVirtioFileSystemDevice?
    let directoryShare: DADirectoryShare
}

struct DAVirtioFileSystemDevice: Codable {
    let tag: String
}

struct DADirectoryShare: Codable {
    let singleDirectoryShare: DASingleDirectoryShare?
    let multipleDirectoryShare: DAMultipleDirectoryShare?
}

struct DASingleDirectoryShare: Codable {
    let directory: DASharedDirectory
}

struct DAMultipleDirectoryShare: Codable {
    let directories: [String: DASharedDirectory]
}

struct DASharedDirectory: Codable {
    let path: String
    let isReadOnly: Bool?
}
