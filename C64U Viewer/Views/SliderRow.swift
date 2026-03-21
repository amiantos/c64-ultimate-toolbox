// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

struct SliderRow: View {
    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 110, alignment: .leading)
            Slider(value: $value, in: range)
            Text(String(format: "%.2f", value))
                .monospacedDigit()
                .frame(width: 40, alignment: .trailing)
        }
    }
}
