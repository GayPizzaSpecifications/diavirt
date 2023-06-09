//
//  ConfigurationModel.swift
//  diavirt
//
//  Created by Alex Zenla on 12/13/21.
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
    let socketDevices: [DASocketDevice]?
    let keyboardDevices: [DAKeyboardDevice]?
    let pointingDevices: [DAPointingDevice]?
    #if arch(arm64)
    let macRestoreImage: DAMacOSRestoreImage?
    #endif
    let startOptions: DAStartOptions?
}

struct DABootLoader: Codable {
    let linuxBootLoader: DALinuxBootLoader?

    #if arch(arm64)
    let macOSBootLoader: DAMacOSBootLoader?
    #endif

    let efiBootLoader: DAEFIBootLoader?
}

struct DALinuxBootLoader: Codable {
    let kernelFilePath: String
    let initialRamdiskPath: String?
    let commandLine: String?
}

#if arch(arm64)
struct DAMacOSBootLoader: Codable {}
#endif

struct DAEFIBootLoader: Codable {
    let efiVariableStore: DAEFIVariableStore
}

struct DAEFIVariableStore: Codable {
    let variableStorePath: String
}

struct DAPlatform: Codable {
    let genericPlatform: DAGenericPlatform?
    let macPlatform: DAMacPlatform?
}

struct DAGenericPlatform: Codable {}

struct DAMacPlatform: Codable {
    let auxiliaryStoragePath: String
    let machineIdentifierPath: String
}

struct DAStorageDevice: Codable {
    let virtioBlockDevice: DAVirtioBlockDevice?
    let usbMassStorageDevice: DAUSBMassStorageDevice?
    let diskImageAttachment: DADiskImageAttachment?
    let networkBlockDeviceAttachment: DANetworkBlockDeviceAttachment?
}

struct DADiskImageAttachment: Codable {
    let imageFilePath: String
    let isReadOnly: Bool?
    let autoCreateSizeInBytes: UInt64?
}

struct DANetworkBlockDeviceAttachment: Codable {
    let networkBlockDeviceUrl: String
    let isForcedReadOnly: Bool?
}

struct DAVirtioBlockDevice: Codable {}

struct DAUSBMassStorageDevice: Codable {}

struct DASerialPort: Codable {
    let stdioSerialAttachment: DAStdioSerialAttachment?
    let wireSerialAttachment: DAWireSerialAttachment?
    let virtioConsoleDevice: DAVirtioConsoleDevice?
    #if DIAVIRT_USE_PRIVATE_APIS
    let pl011SerialDevice: DAPL011SerialDevice?
    let p16550SerialDevice: DA16550SerialDevice?
    #endif
}

struct DAStdioSerialAttachment: Codable {}

struct DAWireSerialAttachment: Codable {
    let tag: String
}

struct DAVirtioConsoleDevice: Codable {}

#if DIAVIRT_USE_PRIVATE_APIS
struct DAPL011SerialDevice: Codable {}

struct DA16550SerialDevice: Codable {}
#endif

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

struct DASocketDevice: Codable {
    let virtioSocketDevice: DAVirtioSocketDevice?
}

struct DAVirtioSocketDevice: Codable {}

struct DAKeyboardDevice: Codable {
    let usbKeyboardDevice: DAUSBKeyboardDevice?
}

struct DAUSBKeyboardDevice: Codable {}

struct DAPointingDevice: Codable {
    let usbScreenCoordinatePointingDevice: DAUSBScreenCoordinatePointingDevice?
}

struct DAUSBScreenCoordinatePointingDevice: Codable {}

#if arch(arm64)
struct DAMacOSRestoreImage: Codable {
    let latestSupportedRestoreImage: DALatestSupportedMacOSRestoreImage?
    let fileRestoreImage: DAFileMacOSRestoreImage?
}

struct DALatestSupportedMacOSRestoreImage: Codable {}

struct DAFileMacOSRestoreImage: Codable {
    let restoreImagePath: String
}
#endif

struct DAStartOptions: Codable {
    #if arch(arm64)
    var macOSStartOptions: DAMacOSStartOptions?
    #endif
}

#if arch(arm64)
struct DAMacOSStartOptions: Codable {
    var startUpFromMacOSRecovery: Bool?
}
#endif
