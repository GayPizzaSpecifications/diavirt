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
