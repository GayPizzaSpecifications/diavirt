//
//  ConfigurationBuilder.swift
//  diavirt
//
//  Created by Alex Zenla on 12/14/21.
//

import Combine
import Foundation
import Virtualization

class DABuildState {
    #if arch(arm64)
    var macRestoreImage: VZMacOSRestoreImage?
    #endif
}

extension DAVirtualMachineConfiguration {
    func preflight(wire: WireProtocol) async throws -> DABuildState {
        let state = DABuildState()
        #if arch(arm64)
        if let macRestoreImage = macRestoreImage {
            state.macRestoreImage = try await macRestoreImage.preflight(wire: wire)
        }
        #endif
        return state
    }

    func build(wire: WireProtocol, state: DABuildState) throws -> VZVirtualMachineConfiguration {
        let configuration = VZVirtualMachineConfiguration()
        try bootLoader.apply(to: configuration, state: state)
        try platform.apply(to: configuration, state: state)
        configuration.cpuCount = cpuCoreCount
        configuration.memorySize = memorySizeInBytes

        if let storageDevices = storageDevices {
            for storageDevice in storageDevices {
                try configuration.storageDevices.append(storageDevice.build(wire: wire))
            }
        }

        if let serialPorts = serialPorts {
            for serialPort in serialPorts {
                try configuration.serialPorts.append(serialPort.build(wire: wire))
            }
        }

        if let entropyDevices = entropyDevices {
            for entropyDevice in entropyDevices {
                try configuration.entropyDevices.append(entropyDevice.build())
            }
        }

        if let memoryBalloonDevices = memoryBalloonDevices {
            for memoryBalloonDevice in memoryBalloonDevices {
                try configuration.memoryBalloonDevices.append(memoryBalloonDevice.build())
            }
        }

        if let networkDevices = networkDevices {
            for networkDevice in networkDevices {
                try configuration.networkDevices.append(networkDevice.build())
            }
        }

        if let graphicsDevices = graphicsDevices {
            for graphicsDevice in graphicsDevices {
                try configuration.graphicsDevices.append(graphicsDevice.build())
            }
        }

        if let directorySharingDevices = directorySharingDevices {
            for directorySharingDevice in directorySharingDevices {
                try configuration.directorySharingDevices.append(directorySharingDevice.build())
            }
        }

        if let socketDevices = socketDevices {
            for socketDevice in socketDevices {
                try configuration.socketDevices.append(socketDevice.build())
            }
        }

        if let keyboardDevices = keyboardDevices {
            for keyboardDevice in keyboardDevices {
                try configuration.keyboards.append(keyboardDevice.build())
            }
        }

        if let pointingDevices = pointingDevices {
            for pointingDevice in pointingDevices {
                try configuration.pointingDevices.append(pointingDevice.build())
            }
        }
        return configuration
    }
}

extension DABootLoader {
    func apply(to configuration: VZVirtualMachineConfiguration, state _: DABuildState) throws {
        if let linuxBootLoader = linuxBootLoader {
            configuration.bootLoader = try linuxBootLoader.build()
        }

        #if DIAVIRT_USE_PRIVATE_APIS
        if let efiBootLoader = efiBootLoader {
            configuration.bootLoader = try efiBootLoader.build()
        }
        #endif

        #if arch(arm64)
        if let macOSBootLoader = macOSBootLoader {
            configuration.bootLoader = try macOSBootLoader.build()
        }
        #endif
    }
}

extension DALinuxBootLoader {
    func build() throws -> VZLinuxBootLoader {
        let kernelURL = URL(fileURLWithPath: kernelFilePath).absoluteURL
        let bootloader = VZLinuxBootLoader(kernelURL: kernelURL)

        if let initialRamdiskPath = initialRamdiskPath {
            let initialRamdiskURL = URL(fileURLWithPath: initialRamdiskPath).absoluteURL
            bootloader.initialRamdiskURL = initialRamdiskURL
        }

        if let commandLine = commandLine {
            bootloader.commandLine = commandLine
        }
        return bootloader
    }
}

#if arch(arm64)
extension DAMacOSBootLoader {
    func build() throws -> VZMacOSBootLoader {
        VZMacOSBootLoader()
    }
}
#endif

extension DAEFIVariableStore {
    func build() throws -> VZEFIVariableStore {
        let variableStoreURL = URL(fileURLWithPath: variableStorePath)
        if FileManager.default.fileExists(atPath: variableStorePath) {
            return VZEFIVariableStore(url: variableStoreURL)
        }
        return try VZEFIVariableStore(creatingVariableStoreAt: variableStoreURL)
    }
}

extension DAEFIBootLoader {
    func build() throws -> VZBootLoader {
        let efiBootLoader = VZEFIBootLoader()
        efiBootLoader.variableStore = try efiVariableStore.build()
        return efiBootLoader
    }
}

extension DAPlatform {
    func apply(to configuration: VZVirtualMachineConfiguration, state: DABuildState) throws {
        if let genericPlatform = genericPlatform {
            configuration.platform = try genericPlatform.build()
        }

        #if arch(arm64)
        if let macPlatform = macPlatform {
            configuration.platform = try macPlatform.build(state: state)
        }
        #endif
    }
}

extension DAGenericPlatform {
    func build() throws -> VZGenericPlatformConfiguration {
        VZGenericPlatformConfiguration()
    }
}

#if arch(arm64)
extension DAMacPlatform {
    func build(state: DABuildState) throws -> VZMacPlatformConfiguration {
        let restoreImage = state.macRestoreImage!
        let configuration = restoreImage.mostFeaturefulSupportedConfiguration!
        let model = configuration.hardwareModel
        let platform = VZMacPlatformConfiguration()
        let auxilaryStorageURL = URL(fileURLWithPath: auxiliaryStoragePath)
        let auxilaryStorage: VZMacAuxiliaryStorage
        if !FileManager.default.fileExists(atPath: auxiliaryStoragePath) {
            auxilaryStorage = try VZMacAuxiliaryStorage(creatingStorageAt: auxilaryStorageURL, hardwareModel: model, options: .allowOverwrite)
        } else {
            auxilaryStorage = VZMacAuxiliaryStorage(contentsOf: auxilaryStorageURL)
        }

        var machineIdentifier: VZMacMachineIdentifier?
        if FileManager.default.fileExists(atPath: machineIdentifierPath) {
            let data = try Data(contentsOf: URL(fileURLWithPath: machineIdentifierPath))
            machineIdentifier = VZMacMachineIdentifier(dataRepresentation: data)
        } else {
            machineIdentifier = VZMacMachineIdentifier()
            let dataToSave = machineIdentifier!.dataRepresentation
            try dataToSave.write(to: URL(fileURLWithPath: machineIdentifierPath))
        }

        platform.auxiliaryStorage = auxilaryStorage
        platform.hardwareModel = configuration.hardwareModel

        if let machineIdentifier = machineIdentifier {
            platform.machineIdentifier = machineIdentifier
        }
        return platform
    }
}
#endif

extension DAStorageDevice {
    func build(wire: WireProtocol) throws -> VZStorageDeviceConfiguration {
        var attachment: VZStorageDeviceAttachment?
        var storage: VZStorageDeviceConfiguration?

        if let diskImageAttachment = diskImageAttachment {
            attachment = try diskImageAttachment.build(wire: wire)
        }

        if let networkBlockDeviceAttachment = networkBlockDeviceAttachment {
            attachment = try networkBlockDeviceAttachment.build()
        }

        if let virtioBlockDevice = virtioBlockDevice {
            storage = try virtioBlockDevice.build(attachment: attachment!)
        }

        if let usbMassStorageDevice = usbMassStorageDevice {
            storage = try usbMassStorageDevice.build(attachment: attachment!)
        }

        return storage!
    }
}

extension DADiskImageAttachment {
    func build(wire: WireProtocol) throws -> VZDiskImageStorageDeviceAttachment {
        let url = URL(fileURLWithPath: imageFilePath).absoluteURL

        var wasDiskAllocated = false
        if let autoCreateSizeInBytes = autoCreateSizeInBytes {
            if !FileManager.default.fileExists(atPath: url.path) {
                let parentFileUrl = url.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: parentFileUrl, withIntermediateDirectories: true)
                createDiskImage(url.path, size: autoCreateSizeInBytes)
                wasDiskAllocated = true
                wire.writeProtocolEvent(NotifyEvent("disk.allocated"))
            }
        }

        wire.trackDiskAllocated(allocated: wasDiskAllocated)

        let readOnly = isReadOnly ?? false
        return try VZDiskImageStorageDeviceAttachment(url: url, readOnly: readOnly)
    }

    private func createDiskImage(_ path: String, size: UInt64) {
        let diskFd = open(path, O_RDWR | O_CREAT, S_IRUSR | S_IWUSR)
        if diskFd == -1 {
            fatalError("Cannot create disk image.")
        }

        var result = ftruncate(diskFd, Int64(size))
        if result != 0 {
            fatalError("ftruncate() failed.")
        }

        result = close(diskFd)
        if result != 0 {
            fatalError("Failed to close the disk image.")
        }
    }
}

extension DANetworkBlockDeviceAttachment {
    func build() throws -> VZNetworkBlockDeviceStorageDeviceAttachment {
        let url = URL(fileURLWithPath: networkBlockDeviceUrl)
        return try VZNetworkBlockDeviceStorageDeviceAttachment(url: url)
    }
}

extension DAVirtioBlockDevice {
    func build(attachment: VZStorageDeviceAttachment) throws -> VZStorageDeviceConfiguration {
        VZVirtioBlockDeviceConfiguration(attachment: attachment)
    }
}

extension DAUSBMassStorageDevice {
    func build(attachment: VZStorageDeviceAttachment) throws -> VZStorageDeviceConfiguration {
        VZUSBMassStorageDeviceConfiguration(attachment: attachment)
    }
}

extension DASerialPort {
    func build(wire: WireProtocol) throws -> VZSerialPortConfiguration {
        var attachment: VZSerialPortAttachment?
        var port: VZSerialPortConfiguration?

        if let stdioSerialAttachment = stdioSerialAttachment {
            attachment = try stdioSerialAttachment.build(wire: wire)
        }

        if let wireSerialAttachment = wireSerialAttachment {
            attachment = try wireSerialAttachment.build(wire: wire)
        }

        if let virtioConsoleDevice = virtioConsoleDevice {
            port = try virtioConsoleDevice.build()
        }

        #if DIAVIRT_USE_PRIVATE_APIS
        if let pl011SerialDevice = pl011SerialDevice {
            port = try pl011SerialDevice.build()
        }

        if let p16550SerialDevice = p16550SerialDevice {
            port = try p16550SerialDevice.build()
        }
        #endif

        port?.attachment = attachment!
        return port!
    }
}

extension DAStdioSerialAttachment {
    func build(wire: WireProtocol) throws -> VZFileHandleSerialPortAttachment {
        let stdinWritePipe = Pipe()
        wire.trackOutputPipe(stdinWritePipe, tag: "stdin")

        FileHandle.standardInput.readabilityHandler = { handle in
            let data = handle.availableData
            do {
                try stdinWritePipe.fileHandleForWriting.write(contentsOf: data)
            } catch {
                wire.writeProtocolEvent(ErrorEvent(error))
            }
        }

        return VZFileHandleSerialPortAttachment(
            fileHandleForReading: stdinWritePipe.fileHandleForReading,
            fileHandleForWriting: FileHandle.standardOutput
        )
    }
}

extension DAWireSerialAttachment {
    func build(wire: WireProtocol) throws -> VZFileHandleSerialPortAttachment {
        let serialInputPipe = Pipe()
        wire.trackInputPipe(serialInputPipe, tag: tag)
        let serialOutputPipe = Pipe()
        wire.trackOutputPipe(serialOutputPipe, tag: tag)
        serialOutputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            wire.writeProtocolEvent(PipeDataEvent(tag: tag, data: data))
        }
        return VZFileHandleSerialPortAttachment(
            fileHandleForReading: serialInputPipe.fileHandleForReading,
            fileHandleForWriting: serialOutputPipe.fileHandleForWriting
        )
    }
}

extension DAVirtioConsoleDevice {
    func build() throws -> VZVirtioConsoleDeviceSerialPortConfiguration {
        VZVirtioConsoleDeviceSerialPortConfiguration()
    }
}

#if DIAVIRT_USE_PRIVATE_APIS
extension DAPL011SerialDevice {
    func build() throws -> VZSerialPortConfiguration {
        VZPrivateUtilities.createPL011SerialPortConfiguration()
    }
}

extension DA16550SerialDevice {
    func build() throws -> VZSerialPortConfiguration {
        VZPrivateUtilities.create16550SerialPortConfiguration()
    }
}
#endif

extension DAEntropyDevice {
    func build() throws -> VZEntropyDeviceConfiguration {
        try (virtioEntropyDevice?.build())!
    }
}

extension DAVirtioEntropyDevice {
    func build() throws -> VZVirtioEntropyDeviceConfiguration {
        VZVirtioEntropyDeviceConfiguration()
    }
}

extension DAMemoryBalloonDevice {
    func build() throws -> VZMemoryBalloonDeviceConfiguration {
        try (virtioTraditionalMemoryBalloonDevice?.build())!
    }
}

extension DAVirtioTraditionalMemoryBalloonDevice {
    func build() throws -> VZVirtioTraditionalMemoryBalloonDeviceConfiguration {
        VZVirtioTraditionalMemoryBalloonDeviceConfiguration()
    }
}

extension DANetworkDevice {
    func build() throws -> VZNetworkDeviceConfiguration {
        var attachment: VZNetworkDeviceAttachment?
        var device: VZNetworkDeviceConfiguration?

        if let natNetworkAttachment = natNetworkAttachment {
            attachment = try natNetworkAttachment.build()
        }

        if let virtioNetworkDevice = virtioNetworkDevice {
            device = try virtioNetworkDevice.build()
        }

        device?.attachment = attachment
        return device!
    }
}

extension DANATNetworkAttachment {
    func build() throws -> VZNATNetworkDeviceAttachment {
        VZNATNetworkDeviceAttachment()
    }
}

extension DAVirtioNetworkDevice {
    func build() throws -> VZVirtioNetworkDeviceConfiguration {
        let device = VZVirtioNetworkDeviceConfiguration()
        if let macAddress = macAddress {
            device.macAddress = VZMACAddress(string: macAddress)!
        }
        return device
    }
}

extension DAGraphicsDevice {
    func build() throws -> VZGraphicsDeviceConfiguration {
        var device: VZGraphicsDeviceConfiguration?

        if let macGraphicsDevice {
            device = try macGraphicsDevice.build()
        }

        if let virtioGraphicsDevice {
            device = try virtioGraphicsDevice.build()
        }

        return device!
    }
}

extension DAMacGraphicsDevice {
    func build() throws -> VZMacGraphicsDeviceConfiguration {
        let device = VZMacGraphicsDeviceConfiguration()
        let displays = try displays.map { display in try display.build() }
        device.displays = displays
        return device
    }
}

extension DAMacGraphicsDisplay {
    func build() throws -> VZMacGraphicsDisplayConfiguration {
        VZMacGraphicsDisplayConfiguration(widthInPixels: widthInPixels,
                                          heightInPixels: heightInPixels,
                                          pixelsPerInch: pixelsPerInch)
    }
}

extension DAVirtioGraphicsDevice {
    func build() throws -> VZVirtioGraphicsDeviceConfiguration {
        let device = VZVirtioGraphicsDeviceConfiguration()
        let scanouts = try scanouts.map { scanout in try scanout.build() }
        device.scanouts = scanouts
        return device
    }
}

extension DAVirtioGraphicsScanout {
    func build() throws -> VZVirtioGraphicsScanoutConfiguration {
        VZVirtioGraphicsScanoutConfiguration(widthInPixels: widthInPixels,
                                             heightInPixels: heightInPixels)
    }
}

extension DADirectorySharingDevice {
    func build() throws -> VZDirectorySharingDeviceConfiguration {
        let share = try directoryShare.build()
        var device: VZDirectorySharingDeviceConfiguration?
        if let virtioFileSystemDevice = virtioFileSystemDevice {
            let fileSystemDevice = try virtioFileSystemDevice.build()
            fileSystemDevice.share = share
            device = fileSystemDevice
        }
        return device!
    }
}

extension DAVirtioFileSystemDevice {
    func build() throws -> VZVirtioFileSystemDeviceConfiguration {
        VZVirtioFileSystemDeviceConfiguration(tag: tag)
    }
}

extension DADirectoryShare {
    func build() throws -> VZDirectoryShare {
        var share: VZDirectoryShare?
        if let singleDirectoryShare = singleDirectoryShare {
            share = try singleDirectoryShare.build()
        }

        if let multipleDirectoryShare = multipleDirectoryShare {
            share = try multipleDirectoryShare.build()
        }

        return share!
    }
}

extension DASingleDirectoryShare {
    func build() throws -> VZSingleDirectoryShare {
        try VZSingleDirectoryShare(directory: directory.build())
    }
}

extension DAMultipleDirectoryShare {
    func build() throws -> VZMultipleDirectoryShare {
        let shares = try directories.mapValues { directory in try directory.build() }
        return VZMultipleDirectoryShare(directories: shares)
    }
}

extension DASharedDirectory {
    func build() throws -> VZSharedDirectory {
        let url = URL(fileURLWithPath: path)
        return VZSharedDirectory(url: url, readOnly: isReadOnly ?? false)
    }
}

extension DASocketDevice {
    func build() throws -> VZSocketDeviceConfiguration {
        var device: VZSocketDeviceConfiguration?

        if let virtioSocketDevice = virtioSocketDevice {
            device = try virtioSocketDevice.build()
        }

        return device!
    }
}

extension DAVirtioSocketDevice {
    func build() throws -> VZVirtioSocketDeviceConfiguration {
        VZVirtioSocketDeviceConfiguration()
    }
}

extension DAKeyboardDevice {
    func build() throws -> VZKeyboardConfiguration {
        var device: VZKeyboardConfiguration?

        if let usbKeyboardDevice = usbKeyboardDevice {
            device = try usbKeyboardDevice.build()
        }

        return device!
    }
}

extension DAUSBKeyboardDevice {
    func build() throws -> VZUSBKeyboardConfiguration {
        VZUSBKeyboardConfiguration()
    }
}

extension DAPointingDevice {
    func build() throws -> VZPointingDeviceConfiguration {
        var device: VZPointingDeviceConfiguration?

        if let usbScreenCoordinatePointingDevice = usbScreenCoordinatePointingDevice {
            device = try usbScreenCoordinatePointingDevice.build()
        }

        return device!
    }
}

extension DAUSBScreenCoordinatePointingDevice {
    func build() throws -> VZUSBScreenCoordinatePointingDeviceConfiguration {
        VZUSBScreenCoordinatePointingDeviceConfiguration()
    }
}

extension DAStartOptions {
    func build() -> VZVirtualMachineStartOptions? {
        #if arch(arm64)
        if let macOSStartOptions {
            return macOSStartOptions.build()
        }
        #endif
        return nil
    }
}

#if arch(arm64)
extension DAMacOSStartOptions {
    func build() -> VZMacOSVirtualMachineStartOptions {
        let options = VZMacOSVirtualMachineStartOptions()
        if let startUpFromMacOSRecovery {
            options.startUpFromMacOSRecovery = startUpFromMacOSRecovery
        }
        return options
    }
}

extension DAMacOSRestoreImage {
    func preflight(wire: WireProtocol) async throws -> VZMacOSRestoreImage {
        wire.writeProtocolEvent(StateEvent("preflight.macRestoreImage.start"))
        var restoreImage: VZMacOSRestoreImage?

        if let latestSupportedRestoreImage = latestSupportedRestoreImage {
            restoreImage = try await latestSupportedRestoreImage.preflight(wire: wire)
        }

        if let fileRestoreImage = fileRestoreImage {
            restoreImage = try await fileRestoreImage.preflight()
        }
        wire.writeProtocolEvent(StateEvent("preflight.macRestoreImage.end"))
        return restoreImage!
    }
}

extension DALatestSupportedMacOSRestoreImage {
    func preflight(wire: WireProtocol) async throws -> VZMacOSRestoreImage {
        let imageRemote = try await VZMacOSRestoreImage.latestSupported
        var downloadProgressObserver: NSKeyValueObservation?

        wire.writeProtocolEvent(StateEvent("installation.download.start"))
        let future: Future<URL?, Error> = Future { promise in
            let task = URLSession.shared.downloadTask(with: imageRemote.url) { url, _, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                promise(.success(url))
            }

            downloadProgressObserver = task.progress.observe(\.fractionCompleted, options: [.initial, .new]) { _, change in
                wire.writeProtocolEvent(InstallationDownloadProgressEvent(progress: change.newValue! * 100.0))
            }
            task.resume()
        }

        let temporaryFileUrl = try await future.value!
        downloadProgressObserver?.invalidate()
        wire.writeProtocolEvent(StateEvent("installation.download.end"))
        let currentFileURL = URL(fileURLWithPath: "restore.ipsw")
        try FileManager.default.moveItem(at: temporaryFileUrl, to: currentFileURL)
        return try await VZMacOSRestoreImage.image(from: currentFileURL)
    }
}

extension DAFileMacOSRestoreImage {
    func preflight() async throws -> VZMacOSRestoreImage {
        try await VZMacOSRestoreImage.image(from: URL(fileURLWithPath: restoreImagePath))
    }
}
#endif
