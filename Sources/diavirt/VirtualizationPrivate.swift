//
//  VirtualizationPrivate.swift
//  diavirt
//
//  Created by Alex Zenla on 3/24/22.
//

#if DIAVIRT_USE_PRIVATE_APIS
import Foundation
import Virtualization

#if arch(arm64)
@objc protocol _VZAppleTouchScreenConfiguration {
    init()
}

@objc protocol _VZUSBTouchScreenConfiguration {
    init()
}

@objc protocol _VZMacKeyboardConfiguration {
    init()
}

@objc protocol _VZMacTrackpadConfiguration {
    init()
}
#endif

@objc protocol _VZUSBMassStorageDeviceConfiguration {
    init(attachment: VZStorageDeviceAttachment)
}

@objc protocol _VZEFIBootLoader {
    init()

    var efiURL: URL { get @objc(setEfiURL:) set }
    var variableStore: _VZEFIVariableStore { get @objc(setVariableStore:) set }
}

@objc protocol _VZEFIVariableStore {
    init(URL: URL) throws
}

@objc protocol _VZGDBDebugStubConfiguration {
    init(port: Int)
}

@objc protocol _VZVirtualMachineConfiguration {
    var _debugStub: _VZGDBDebugStubConfiguration { get @objc(_setDebugStub:) set }
}

@objc protocol _VZVNCAuthenticationSecurityConfiguration {
    init(password: String)
}

@objc protocol _VZVNCNoSecuritySecurityConfiguration {
    init()
}

@objc protocol _VZVNCServer {
    init(port: Int, queue: DispatchQueue, securityConfiguration: AnyObject)

    var virtualMachine: VZVirtualMachine { get @objc(setVirtualMachine:) set }
    var port: Int { get }

    func start()
    func stop()
}

@objc protocol _VZPL011SerialPortConfiguration {
    init()
}

@objc protocol _VZ16550SerialPortConfiguration {
    init()
}

extension VZVirtualMachineConfiguration {
    func setGdbDebugStub(_ gdb: _VZGDBDebugStubConfiguration) {
        unsafeBitCast(self, to: _VZVirtualMachineConfiguration.self)._debugStub = gdb
    }
}

enum VZPrivateUtilities {
    static func createVncServer(port: Int, queue: DispatchQueue, password: String? = nil) -> _VZVNCServer {
        unsafeBitCast(NSClassFromString("_VZVNCServer")!, to: _VZVNCServer.Type.self).init(port: port, queue: queue, securityConfiguration: password != nil ? createVncServerAuthentication(password: password!) : createVncServerNoSecurity())
    }

    static func createVncServerNoSecurity() -> _VZVNCNoSecuritySecurityConfiguration {
        unsafeBitCast(NSClassFromString("_VZVNCNoSecuritySecurityConfiguration")!, to: _VZVNCNoSecuritySecurityConfiguration.Type.self).init()
    }

    static func createVncServerAuthentication(password: String) -> _VZVNCAuthenticationSecurityConfiguration {
        unsafeBitCast(NSClassFromString("_VZVNCAuthenticationSecurityConfiguration")!, to: _VZVNCAuthenticationSecurityConfiguration.Type.self).init(password: password)
    }

    static func createGdbDebugStub(_ port: Int) -> _VZGDBDebugStubConfiguration {
        unsafeBitCast(NSClassFromString("_VZGDBDebugStubConfiguration")!, to: _VZGDBDebugStubConfiguration.Type.self).init(port: port)
    }

    static func createPL011SerialPortConfiguration() -> VZSerialPortConfiguration {
        let serialPort = unsafeBitCast(NSClassFromString("_VZPL011SerialPortConfiguration")!, to: _VZPL011SerialPortConfiguration.Type.self).init()
        return unsafeBitCast(serialPort, to: VZSerialPortConfiguration.self)
    }

    static func create16550SerialPortConfiguration() -> VZSerialPortConfiguration {
        let serialPort = unsafeBitCast(NSClassFromString("_VZ16550SerialPortConfiguration")!, to: _VZ16550SerialPortConfiguration.Type.self).init()
        return unsafeBitCast(serialPort, to: VZSerialPortConfiguration.self)
    }
}
#endif
