//
//  TerminalMode.swift
//  diavirt
//
//  Created by Kenneth Endfinger on 12/18/21.
//

import Foundation

struct TerminalMode {
    private var attributeStack = [termios]()

    private mutating func captureCurrentAttributes() -> termios {
        var attributes = termios()
        tcgetattr(FileHandle.standardInput.fileDescriptor, &attributes)
        attributeStack.append(attributes)
        var attributesToReturn = termios()
        memcpy(&attributesToReturn, &attributes, MemoryLayout.size(ofValue: attributes))
        return attributesToReturn
    }

    private mutating func captureAndModifyAttributes(change: (inout termios) -> Void) {
        var attributesToChange = captureCurrentAttributes()
        change(&attributesToChange)
        writeNewAttributes(attributes: &attributesToChange)
    }

    private mutating func writeNewAttributes(attributes: inout termios) {
        tcsetattr(FileHandle.standardInput.fileDescriptor, TCSANOW, &attributes)
    }

    mutating func restoreOriginalAttributes() {
        if var last = attributeStack.popLast() {
            writeNewAttributes(attributes: &last)
        }
    }

    mutating func enableRawMode() {
        captureAndModifyAttributes { attributes in
            attributes.c_iflag &= ~tcflag_t(ICRNL)
            attributes.c_lflag &= ~tcflag_t(ICANON | ECHO)
        }
    }
}
