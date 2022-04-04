//
//  WireModel.swift
//  diavirt
//
//  Created by Kenneth Endfinger on 12/14/21.
//

import Foundation

protocol WireEvent: Codable {
    var type: String { get }

    func toUserMessage() -> String?
}

protocol WireProtocol {
    func writeProtocolEvent<T: WireEvent>(_ event: T)
    func trackInputPipe(_ pipe: Pipe, tag: String)
    func trackOutputPipe(_ pipe: Pipe, tag: String)
    func trackDiskAllocated(allocated: Bool)
}

struct SimpleEvent: WireEvent {
    var type: String

    init(type: String) {
        self.type = type
    }

    func toUserMessage() -> String? {
        nil
    }
}

struct StateEvent: WireEvent {
    var type: String = "state"
    let state: String

    init(_ state: String) {
        self.state = state
    }

    func toUserMessage() -> String? {
        nil
    }
}

struct NotifyEvent: WireEvent {
    var type: String = "notify"
    let event: String

    init(_ event: String) {
        self.event = event
    }

    func toUserMessage() -> String? {
        nil
    }
}

struct ErrorEvent: WireEvent {
    var type: String = "error"
    let error: String

    init(_ error: Error) {
        self.error = error.localizedDescription
    }

    func toUserMessage() -> String? {
        "ERROR: \(error)"
    }
}

struct PipeDataEvent: WireEvent {
    var type: String = "data"
    let tag: String
    let data: Data

    init(tag: String, data: Data) {
        self.tag = tag
        self.data = data
    }

    func toUserMessage() -> String? {
        nil
    }
}

struct InstallationProgressEvent: WireEvent {
    var type: String = "installation.progress"
    let progress: Double

    init(progress: Double) {
        self.progress = progress
    }

    func toUserMessage() -> String? {
        "Installation Progress: \(Int64(progress))%"
    }
}

struct InstallationDownloadProgressEvent: WireEvent {
    var type: String = "installation.download.progress"
    let progress: Double

    init(progress: Double) {
        self.progress = progress
    }

    func toUserMessage() -> String? {
        "Installer Download Progress: \(String(format: "%.4f", progress))%"
    }
}
