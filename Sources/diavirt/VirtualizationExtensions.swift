//
//  VirtualizationExtensions.swift
//  diavirt
//
//  Created by Kenneth Endfinger on 12/20/21.
//

import Foundation
import Virtualization

extension VZMacOSRestoreImage {
    static func fetchLatestSupported() async throws -> VZMacOSRestoreImage {
        try await withUnsafeThrowingContinuation { continuation in
            fetchLatestSupported { result in
                continuation.resume(with: result)
            }
        }
    }

    static func load(from url: URL) async throws -> VZMacOSRestoreImage {
        try await withUnsafeThrowingContinuation { continuation in
            load(from: url) { result in
                continuation.resume(with: result)
            }
        }
    }
}
