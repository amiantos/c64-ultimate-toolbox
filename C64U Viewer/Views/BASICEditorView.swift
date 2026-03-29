// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import AppKit

// MARK: - Syntax Highlighting

struct BASICSyntaxHighlighter {
    static let defaultFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)

    static let defaultColor = NSColor.textColor
    static let keywordColor = NSColor.systemBlue
    static let stringColor = NSColor.systemGreen
    static let numberColor = NSColor.systemOrange
    static let lineNumberColor = NSColor.systemYellow
    static let commentColor = NSColor.systemGray
    static let specialCodeColor = NSColor.systemPink
    static let errorColor = NSColor.systemRed

    static func highlight(_ text: String) -> NSAttributedString {
        let result = NSMutableAttributedString()

        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        for (index, line) in lines.enumerated() {
            if index > 0 {
                result.append(NSAttributedString(string: "\n", attributes: defaultAttributes))
            }
            result.append(highlightLine(String(line)))
        }

        return result
    }

    private static var defaultAttributes: [NSAttributedString.Key: Any] {
        [.font: defaultFont, .foregroundColor: defaultColor]
    }

    private static func highlightLine(_ line: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        var remaining = line[line.startIndex...]

        // Skip leading whitespace
        let whitespace = remaining.prefix(while: { $0 == " " || $0 == "\t" })
        if !whitespace.isEmpty {
            result.append(styled(String(whitespace), color: defaultColor))
            remaining = remaining[whitespace.endIndex...]
        }

        // Parse line number
        let digits = remaining.prefix(while: { $0.isNumber })
        if !digits.isEmpty {
            result.append(styled(String(digits), color: lineNumberColor))
            remaining = remaining[digits.endIndex...]
        }

        // Skip space after line number
        let space = remaining.prefix(while: { $0 == " " })
        if !space.isEmpty {
            result.append(styled(String(space), color: defaultColor))
            remaining = remaining[space.endIndex...]
        }

        // Tokenize the rest
        var inQuotes = false
        var inRemark = false
        let lowered = remaining.lowercased()
        var lowIdx = lowered.startIndex

        while remaining.startIndex < remaining.endIndex {
            if inRemark {
                result.append(styled(String(remaining), color: commentColor))
                break
            }

            if inQuotes {
                // Inside a string literal
                let char = remaining[remaining.startIndex]
                if char == "\"" {
                    result.append(styled("\"", color: stringColor))
                    remaining = remaining[remaining.index(after: remaining.startIndex)...]
                    lowIdx = lowered.index(after: lowIdx)
                    inQuotes = false
                } else if char == "{" {
                    // Special code inside string
                    if let (match, len) = matchSpecialCode(lowered[lowIdx...]) {
                        let origText = String(remaining[remaining.startIndex..<remaining.index(remaining.startIndex, offsetBy: len)])
                        result.append(styled(origText, color: specialCodeColor))
                        remaining = remaining[remaining.index(remaining.startIndex, offsetBy: len)...]
                        lowIdx = lowered.index(lowIdx, offsetBy: len)
                        _ = match
                    } else {
                        // Unknown {code} — highlight as error
                        if let closeIdx = remaining[remaining.index(after: remaining.startIndex)...].firstIndex(of: "}") {
                            let endIdx = remaining.index(after: closeIdx)
                            result.append(styled(String(remaining[remaining.startIndex..<endIdx]), color: errorColor))
                            let len = remaining.distance(from: remaining.startIndex, to: endIdx)
                            remaining = remaining[endIdx...]
                            lowIdx = lowered.index(lowIdx, offsetBy: len)
                        } else {
                            result.append(styled(String(remaining[remaining.startIndex...remaining.startIndex]), color: stringColor))
                            remaining = remaining[remaining.index(after: remaining.startIndex)...]
                            lowIdx = lowered.index(after: lowIdx)
                        }
                    }
                } else {
                    result.append(styled(String(char), color: stringColor))
                    remaining = remaining[remaining.index(after: remaining.startIndex)...]
                    lowIdx = lowered.index(after: lowIdx)
                }
                continue
            }

            // Not in quotes — try to match keyword
            let lowRemaining = lowered[lowIdx...]
            if let (keyword, _) = matchKeyword(lowRemaining) {
                let len = keyword.count
                let origText = String(remaining[remaining.startIndex..<remaining.index(remaining.startIndex, offsetBy: len)])
                if keyword == "rem" {
                    result.append(styled(origText, color: commentColor))
                    remaining = remaining[remaining.index(remaining.startIndex, offsetBy: len)...]
                    lowIdx = lowered.index(lowIdx, offsetBy: len)
                    inRemark = true
                } else {
                    result.append(styled(origText, color: keywordColor))
                    remaining = remaining[remaining.index(remaining.startIndex, offsetBy: len)...]
                    lowIdx = lowered.index(lowIdx, offsetBy: len)
                }
                continue
            }

            let char = remaining[remaining.startIndex]

            if char == "\"" {
                inQuotes = true
                result.append(styled("\"", color: stringColor))
                remaining = remaining[remaining.index(after: remaining.startIndex)...]
                lowIdx = lowered.index(after: lowIdx)
                continue
            }

            if char.isNumber {
                // Highlight number sequences
                let numChars = remaining.prefix(while: { $0.isNumber || $0 == "." })
                result.append(styled(String(numChars), color: numberColor))
                let len = numChars.count
                remaining = remaining[remaining.index(remaining.startIndex, offsetBy: len)...]
                lowIdx = lowered.index(lowIdx, offsetBy: len)
                continue
            }

            // Default character
            result.append(styled(String(char), color: defaultColor))
            remaining = remaining[remaining.index(after: remaining.startIndex)...]
            lowIdx = lowered.index(after: lowIdx)
        }

        return result
    }

    private static func styled(_ text: String, color: NSColor) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [
            .font: defaultFont,
            .foregroundColor: color,
        ])
    }

    private static func matchKeyword(_ s: Substring) -> (String, UInt8)? {
        for (keyword, token) in BASICTokenizer.tokens where keyword.count > 1 {
            if s.hasPrefix(keyword) {
                // Make sure it's not a prefix of a variable name (e.g., "top" shouldn't match "to")
                let afterIdx = s.index(s.startIndex, offsetBy: keyword.count)
                if afterIdx < s.endIndex {
                    let next = s[afterIdx]
                    // If keyword ends with $ or ( it's unambiguous
                    if keyword.hasSuffix("$") || keyword.hasSuffix("(") {
                        return (keyword, token)
                    }
                    // If next char is a letter, it's a variable name, not a keyword
                    if next.isLetter {
                        continue
                    }
                }
                return (keyword, token)
            }
        }
        return nil
    }

    private static func matchSpecialCode(_ s: Substring) -> (String, Int)? {
        for (code, _) in BASICTokenizer.specialCodes {
            if s.hasPrefix(code) {
                return (code, code.count)
            }
        }
        return nil
    }
}

// MARK: - NSTextView-backed Editor with Syntax Highlighting

struct BASICEditorView: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.font = BASICSyntaxHighlighter.defaultFont
        textView.backgroundColor = NSColor(white: 0.1, alpha: 1.0)
        textView.insertionPointColor = .white
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.delegate = context.coordinator

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor(white: 0.1, alpha: 1.0)
        scrollView.borderType = .noBorder

        // Apply initial highlighting
        context.coordinator.textView = textView
        context.coordinator.applyHighlighting()

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            context.coordinator.isUpdating = true
            textView.string = text
            context.coordinator.applyHighlighting()
            textView.selectedRanges = selectedRanges
            context.coordinator.isUpdating = false
        }
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        var textView: NSTextView?
        var isUpdating = false

        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView, !isUpdating else { return }
            text.wrappedValue = textView.string
            applyHighlighting()
        }

        func applyHighlighting() {
            guard let textView else { return }
            let highlighted = BASICSyntaxHighlighter.highlight(textView.string)

            isUpdating = true
            let selectedRanges = textView.selectedRanges
            textView.textStorage?.beginEditing()
            textView.textStorage?.setAttributedString(highlighted)
            textView.textStorage?.endEditing()
            textView.selectedRanges = selectedRanges
            isUpdating = false
        }
    }
}
