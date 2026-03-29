// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

struct ControlSidebarView: View {
    @Bindable var connection: C64Connection

    var body: some View {
        List(selection: $connection.activeToolPanel) {
            ForEach(ToolPanelType.allCases) { tool in
                Label(tool.label, systemImage: tool.icon)
                    .tag(tool)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Tools")
    }
}
