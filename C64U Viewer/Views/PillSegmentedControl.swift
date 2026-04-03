// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import AppKit

/// A pill-shaped segmented control similar to Xcode's inspector tab switcher.
/// The outer shape is a rounded pill, and the selected segment is highlighted
/// with an accent-colored pill inside.
final class PillSegmentedControl: NSView {
    var labels: [String] {
        didSet { rebuildSegments(); needsDisplay = true }
    }

    var selectedSegment: Int = 0 {
        didSet { needsDisplay = true }
    }

    var target: AnyObject?
    var action: Selector?

    private var trackingArea: NSTrackingArea?
    private var hoveredSegment: Int = -1
    private var segmentButtons: [NSView] = []

    init(labels: [String]) {
        self.labels = labels
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        rebuildSegments()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize {
        let totalWidth = labels.reduce(CGFloat(0)) { sum, label in
            let size = label.size(withAttributes: [.font: NSFont.systemFont(ofSize: 11, weight: .medium)])
            return sum + size.width + 24
        }
        return NSSize(width: totalWidth + 6, height: 26)
    }

    private func rebuildSegments() {
        segmentButtons.forEach { $0.removeFromSuperview() }
        segmentButtons.removeAll()
        invalidateIntrinsicContentSize()
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let bounds = self.bounds.insetBy(dx: 0.5, dy: 0.5)
        let outerPath = NSBezierPath(roundedRect: bounds, xRadius: bounds.height / 2, yRadius: bounds.height / 2)

        // Outer pill background
        (isDark ? NSColor.white.withAlphaComponent(0.08) : NSColor.black.withAlphaComponent(0.05)).setFill()
        outerPath.fill()
        (isDark ? NSColor.white.withAlphaComponent(0.15) : NSColor.black.withAlphaComponent(0.12)).setStroke()
        outerPath.lineWidth = 0.5
        outerPath.stroke()

        let segmentRects = computeSegmentRects()

        // Draw selected segment pill
        if selectedSegment >= 0, selectedSegment < segmentRects.count {
            let selectedRect = segmentRects[selectedSegment].insetBy(dx: 3, dy: 3)
            let selectedPath = NSBezierPath(roundedRect: selectedRect, xRadius: selectedRect.height / 2, yRadius: selectedRect.height / 2)
            NSColor.controlAccentColor.setFill()
            selectedPath.fill()
        }

        // Draw labels
        for (i, label) in labels.enumerated() {
            let rect = segmentRects[i]
            let isSelected = i == selectedSegment
            let isHovered = i == hoveredSegment && !isSelected

            let style = NSMutableParagraphStyle()
            style.alignment = .center

            let color: NSColor
            if isSelected {
                color = .white
            } else if isHovered {
                color = .labelColor
            } else {
                color = .secondaryLabelColor
            }

            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11, weight: isSelected ? .semibold : .medium),
                .foregroundColor: color,
                .paragraphStyle: style,
            ]
            let size = label.size(withAttributes: attrs)
            let textRect = NSRect(
                x: rect.origin.x,
                y: rect.origin.y + (rect.height - size.height) / 2,
                width: rect.width,
                height: size.height
            )
            label.draw(in: textRect, withAttributes: attrs)
        }
    }

    private func computeSegmentRects() -> [NSRect] {
        let count = labels.count
        guard count > 0 else { return [] }
        let segmentWidth = bounds.width / CGFloat(count)
        return (0..<count).map { i in
            NSRect(x: CGFloat(i) * segmentWidth, y: 0, width: segmentWidth, height: bounds.height)
        }
    }

    // MARK: - Mouse Handling

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow], owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let newHovered = segmentAt(point)
        if newHovered != hoveredSegment {
            hoveredSegment = newHovered
            needsDisplay = true
        }
    }

    override func mouseExited(with event: NSEvent) {
        hoveredSegment = -1
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let segment = segmentAt(point)
        if segment >= 0, segment != selectedSegment {
            selectedSegment = segment
            needsDisplay = true
            if let target = target, let action = action {
                NSApp.sendAction(action, to: target, from: self)
            }
        }
    }

    private func segmentAt(_ point: NSPoint) -> Int {
        let rects = computeSegmentRects()
        for (i, rect) in rects.enumerated() {
            if rect.contains(point) { return i }
        }
        return -1
    }
}
