// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation

/// Inspector panels opened via toolbar buttons on the right side
enum InspectorPanel: String, CaseIterable {
    case basicScratchpad
    case system
    case displayAndAudio

    var label: String {
        switch self {
        case .basicScratchpad: "BASIC Scratchpad"
        case .system: "System"
        case .displayAndAudio: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .basicScratchpad: "chevron.left.forwardslash.chevron.right"
        case .system: "gearshape"
        case .displayAndAudio: "tv"
        }
    }

    var preferredWidth: CGFloat {
        switch self {
        case .basicScratchpad: return 500
        case .system: return 420
        case .displayAndAudio: return 400
        }
    }
}
