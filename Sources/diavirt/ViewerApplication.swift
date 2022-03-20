//
//  Viewer.swift
//  diavirt
//
//  Created by Kenneth Endfinger on 12/14/21.
//

import Foundation
import SwiftUI
import Virtualization

struct DiavirtApp: App {
    var body: some Scene {
        WindowGroup {
            GlobalMachineView()
        }
    }
}

struct GlobalMachineView: View {
    @State
    var machine: VZVirtualMachine?

    var body: some View {
        VirtualMachineView(machine)
            .task {
                self.machine = DiavirtCommand.Global.machine?.machine
            }
    }
}

struct VirtualMachineView: NSViewRepresentable {
    typealias NSViewType = VZVirtualMachineView

    let virtualMachine: VZVirtualMachine?

    init(_ virtualMachine: VZVirtualMachine?) {
        self.virtualMachine = virtualMachine
    }

    func makeNSView(context _: Context) -> VZVirtualMachineView {
        VZVirtualMachineView()
    }

    func updateNSView(_ view: VZVirtualMachineView, context _: Context) {
        view.virtualMachine = virtualMachine
    }
}
