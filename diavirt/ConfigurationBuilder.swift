//
//  ConfigurationBuilder.swift
//  diavirt
//
//  Created by Kenneth Endfinger on 12/14/21.
//

import Foundation
import Virtualization

extension DAVirtualMachineConfiguration {
    func build(wire: WireProtocol) throws -> VZVirtualMachineConfiguration {
        let configuration = VZVirtualMachineConfiguration()
        try bootLoader.apply(to: configuration)
        try platform.apply(to: configuration)
        configuration.cpuCount = cpuCoreCount
        configuration.memorySize = memorySizeInBytes

        if let storageDevices = storageDevices {
            for storageDevice in storageDevices {
                configuration.storageDevices.append(try storageDevice.build())
            }
        }

        if let serialPorts = serialPorts {
            for serialPort in serialPorts {
                configuration.serialPorts.append(try serialPort.build(wire: wire))
            }
        }

        if let entropyDevices = entropyDevices {
            for entropyDevice in entropyDevices {
                configuration.entropyDevices.append(try entropyDevice.build())
            }
        }

        if let memoryBalloonDevices = memoryBalloonDevices {
            for memoryBalloonDevice in memoryBalloonDevices {
                configuration.memoryBalloonDevices.append(try memoryBalloonDevice.build())
            }
        }

        if let networkDevices = networkDevices {
            for networkDevice in networkDevices {
                configuration.networkDevices.append(try networkDevice.build())
            }
        }

        if let graphicsDevices = graphicsDevices {
            for graphicsDevice in graphicsDevices {
                configuration.graphicsDevices.append(try graphicsDevice.build())
            }
        }

        return configuration
    }
}

extension DABootLoader {
    func apply(to configuration: VZVirtualMachineConfiguration) throws {
        if let linux = linuxBootLoader {
            configuration.bootLoader = linux.build()
        }
    }
}

extension DALinuxBootLoader {
    func build() -> VZLinuxBootLoader {
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

extension DAPlatform {
    func apply(to configuration: VZVirtualMachineConfiguration) throws {
        if let genericPlatform = genericPlatform {
            configuration.platform = try genericPlatform.build()
        }
    }
}

extension DAGenericPlatform {
    func build() throws -> VZGenericPlatformConfiguration {
        VZGenericPlatformConfiguration()
    }
}

extension DAStorageDevice {
    func build() throws -> VZStorageDeviceConfiguration {
        var attachment: VZStorageDeviceAttachment?
        var storage: VZStorageDeviceConfiguration?

        if let diskImageAttachment = diskImageAttachment {
            attachment = try diskImageAttachment.build()
        }

        if let virtioBlockDevice = virtioBlockDevice {
            storage = try virtioBlockDevice.build(attachment: attachment!)
        }
        return storage!
    }
}

extension DADiskImageAttachment {
    func build() throws -> VZDiskImageStorageDeviceAttachment {
        let url = URL(fileURLWithPath: imageFilePath).absoluteURL
        let readOnly = isReadOnly ?? false
        return try VZDiskImageStorageDeviceAttachment(url: url, readOnly: readOnly)
    }
}

extension DAVirtioBlockDevice {
    func build(attachment: VZStorageDeviceAttachment) throws -> VZStorageDeviceConfiguration {
        VZVirtioBlockDeviceConfiguration(attachment: attachment)
    }
}

extension DASerialPort {
    func build(wire: WireProtocol) throws -> VZSerialPortConfiguration {
        var attachment: VZSerialPortAttachment?
        var port: VZSerialPortConfiguration?

        if let stdioSerialAttachment = stdioSerialAttachment {
            attachment = try stdioSerialAttachment.build()
        }

        if let wireSerialAttachment = wireSerialAttachment {
            attachment = try wireSerialAttachment.build(wire: wire)
        }

        if let virtioConsoleDevice = virtioConsoleDevice {
            port = try virtioConsoleDevice.build()
        }

        port?.attachment = attachment!
        return port!
    }
}

extension DAStdioSerialAttachment {
    func build() throws -> VZFileHandleSerialPortAttachment {
        var attributes = termios()
        tcgetattr(FileHandle.standardInput.fileDescriptor, &attributes)
        attributes.c_iflag &= ~tcflag_t(ICRNL)
        attributes.c_lflag &= ~tcflag_t(ICANON | ECHO)
        tcsetattr(FileHandle.standardInput.fileDescriptor, TCSANOW, &attributes)

        return VZFileHandleSerialPortAttachment(
            fileHandleForReading: FileHandle.standardInput,
            fileHandleForWriting: FileHandle.standardOutput
        )
    }
}

extension DAWireSerialAttachment {
    func build(wire: WireProtocol) throws -> VZFileHandleSerialPortAttachment {
        let serialInputPipe = Pipe()
        wire.trackDataPipe(serialInputPipe, tag: "\(tag).input")
        let serialOutputPipe = Pipe()
        wire.trackDataPipe(serialOutputPipe, tag: "\(tag).output")
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

extension DAEntropyDevice {
    func build() throws -> VZEntropyDeviceConfiguration {
        (try virtioEntropyDevice?.build())!
    }
}

extension DAVirtioEntropyDevice {
    func build() throws -> VZVirtioEntropyDeviceConfiguration {
        VZVirtioEntropyDeviceConfiguration()
    }
}

extension DAMemoryBalloonDevice {
    func build() throws -> VZMemoryBalloonDeviceConfiguration {
        (try virtioTraditionalMemoryBalloonDevice?.build())!
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
        (try macGraphicsDevice?.build())!
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
