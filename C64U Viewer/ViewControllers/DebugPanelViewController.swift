// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import AppKit

/// Container for the bottom debug panel — Memory Browser (left) + 6510 Monitor (right)
final class DebugPanelViewController: NSSplitViewController {
    let connection: C64Connection

    init(connection: C64Connection) {
        self.connection = connection
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()

        splitView.isVertical = true

        let memoryBrowser = MemoryBrowserViewController(connection: connection)
        let debugMonitor = DebugMonitorViewController(connection: connection)

        let memItem = NSSplitViewItem(viewController: memoryBrowser)
        memItem.minimumThickness = 540

        let monItem = NSSplitViewItem(viewController: debugMonitor)
        monItem.minimumThickness = 200

        addSplitViewItem(memItem)
        addSplitViewItem(monItem)
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        if !hasSetInitialPosition {
            hasSetInitialPosition = true
            splitView.setPosition(540, ofDividerAt: 0)
        }
    }

    private var hasSetInitialPosition = false
}
