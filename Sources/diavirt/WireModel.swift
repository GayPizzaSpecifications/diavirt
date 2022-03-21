//
//  WireModel.swift
//  diavirt
//
//  Created by Kenneth Endfinger on 12/14/21.
//

import Foundation

protocol WireEvent: Codable {
    var type: String { get }
}

protocol WireProtocol {
    func writeProtocolEvent<T: WireEvent>(_ event: T)
    func trackInputPipe(_ pipe: Pipe, tag: String)
    func trackOutputPipe(_ pipe: Pipe, tag: String)
}

struct SimpleEvent: WireEvent {
    var type: String

    init(type: String) {
        self.type = type
    }
}

struct StateEvent: WireEvent {
    var type: String = "state"
    let state: String

    init(_ state: String) {
        self.state = state
    }
}

struct ErrorEvent: WireEvent {
    var type: String = "error"
    let error: String

    init(_ error: Error) {
        self.error = error.localizedDescription
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
}

struct InstallationProgressEvent: WireEvent {
    var type: String = "installation.progress"
    let progress: Double
    
    init(progress: Double) {
        self.progress = progress
    }
}
