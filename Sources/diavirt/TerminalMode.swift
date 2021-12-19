//
//  TerminalMode.swift
//  diavirt
//
//  Created by Kenneth Endfinger on 12/18/21.
//

import Foundation

struct TerminalMode {
    private var originalAttributes: termios?
    private var attributes = termios()

    private mutating func loadCurrentAttributes() {
        tcgetattr(FileHandle.standardInput.fileDescriptor, &attributes)
        if originalAttributes == nil {
            originalAttributes = termios()
            tcgetattr(FileHandle.standardInput.fileDescriptor, &attributes)
        }
    }

    private mutating func saveCurrentAttributes() {
        tcsetattr(FileHandle.standardInput.fileDescriptor, TCSANOW, &attributes)
    }

    mutating func restoreOriginalAttributes() {
        if let originalAttributes = originalAttributes {
            attributes = originalAttributes
            saveCurrentAttributes()
        }
    }

    mutating func enableRawMode() {
        loadCurrentAttributes()
        attributes.c_iflag &= ~tcflag_t(ICRNL)
        attributes.c_lflag &= ~tcflag_t(ICANON | ECHO)
        saveCurrentAttributes()
    }
}
