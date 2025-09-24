//
//  EditorViewModel.swift
//  Precision Keyboard
//
//  Created by Ninad Patil on 24/09/25.
//

import Foundation
import SwiftUI
import UIKit

@MainActor
final class EditorViewModel: ObservableObject {
    // MARK: - Public State
    @Published var text: String
    @Published var selected: NSRange = .init(location: 0, length: 0)

    // Precision UI
    @Published var precisionOn: Bool = false
    @Published var loupeImage: UIImage? = nil
    @Published var hint: String? = nil // e.g., "Long-press to use Precision mode"

    // MARK: - Metrics
    private var startedAt: Date = Date()
    private var selectionChangeCount: Int = 0
    private var netDeltaChars: Int = 0
    private var lastAnchorIndex: Int = 0
    private var usedPrecisionEver: Bool = false

    // MARK: - Caret/Loupe
    private weak var sourceView: UIView?
    private var lastCaretRect: CGRect = .zero

    // MARK: - Callbacks
    var onAdvance: (() -> Void)?
    var onFinish: ((MetricEvent) -> Void)?

    // MARK: - Task Context
    let task: StudyTask
    let sessionId: String

    // MARK: - Init
    init(task: StudyTask, sessionId: String) {
        self.task = task
        self.sessionId = sessionId
        self.text = task.initialText
        self.startedAt = Date()
        self.lastAnchorIndex = 0
    }

    // MARK: - Selection Tracking
    func onSelectionChanged(_ newRange: NSRange) {
        let newIndex = anchorIndex(for: newRange)
        let delta = abs(newIndex - lastAnchorIndex)
        netDeltaChars += delta
        selectionChangeCount += 1
        lastAnchorIndex = newIndex
        checkAutoComplete(current: newRange)
    }

    private func anchorIndex(for range: NSRange) -> Int {
        range.location + range.length // end index (caret if length == 0)
    }

    // MARK: - Loupe Handling
    func setCaretRect(_ rect: CGRect, sourceView: UIView?) {
        self.lastCaretRect = rect
        self.sourceView = sourceView
        if precisionOn { refreshLoupe() }
    }

    func togglePrecision(_ on: Bool) {
        // Never enable precision UI for standard tasks
        guard task.method == .precision else {
            precisionOn = false
            loupeImage = nil
            return
        }
        precisionOn = on
        if on {
            usedPrecisionEver = true
            refreshLoupe()
        } else {
            loupeImage = nil
        }
    }

    func refreshLoupe() {
        guard let v = sourceView else { return }
        // Full-width strip centered on caret/selection Y
        let H: CGFloat = 160
        let bounds = v.bounds
        let yCenter = lastCaretRect.midY.isFinite ? lastCaretRect.midY : bounds.midY
        let y = max(0, min(bounds.height - H, yCenter - H/2))
        let rect = CGRect(x: 0, y: y, width: bounds.width, height: H)
        loupeImage = v.snapshot(of: rect, afterScreenUpdates: false)
    }

    // MARK: - Matching (exact) + snap-to-target if selection includes only boundary whitespace/punct
    private func isExactMatch(_ range: NSRange) -> Bool {
        let ns = text as NSString
        guard range.location != NSNotFound, range.upperBound <= ns.length else { return false }
        let sel = ns.substring(with: range)
        if task.caseSensitive {
            return sel == task.target
        } else {
            return sel.caseInsensitiveCompare(task.target) == .orderedSame
        }
    }

    private func expectedRange() -> NSRange? {
        let ns = text as NSString
        let opts: NSString.CompareOptions = task.caseSensitive ? [] : .caseInsensitive
        let r = ns.range(of: task.target, options: opts)
        return r.location == NSNotFound ? nil : r
    }

    /// If current selection fully contains the expected target and extras are only whitespace/punctuation,
    /// snap selection to the exact target range and return it.
    private func snapToTargetIfContained(in current: NSRange) -> NSRange? {
        guard let exp = expectedRange() else { return nil }
        // containment: current.start <= exp.start && current.end >= exp.end
        guard current.location <= exp.location, current.upperBound >= exp.upperBound else { return nil }
        if current == exp { return exp }

        let ns = text as NSString
        let allowed = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)

        // left extra
        let leftLen = exp.location - current.location
        if leftLen > 0 {
            let left = ns.substring(with: NSRange(location: current.location, length: leftLen))
            if !left.unicodeScalars.allSatisfy({ allowed.contains($0) }) { return nil }
        }
        // right extra
        let rightLen = current.upperBound - exp.upperBound
        if rightLen > 0 {
            let right = ns.substring(with: NSRange(location: exp.upperBound, length: rightLen))
            if !right.unicodeScalars.allSatisfy({ allowed.contains($0) }) { return nil }
        }
        return exp
    }

    private func checkAutoComplete(current: NSRange) {
        if isExactMatch(current) {
            if task.method == .precision && !usedPrecisionEver {
                hint = "Long-press to use Precision mode for this task."
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                return
            }
            finishAndAdvance(final: current)
            return
        }
        // If user selected a bit more but only whitespace/punct around the target, snap & advance.
        if let snapped = snapToTargetIfContained(in: current) {
            // Visually correct the selection on screen
            selected = snapped
            if task.method == .precision && !usedPrecisionEver {
                hint = "Long-press to use Precision mode for this task."
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                return
            }
            finishAndAdvance(final: snapped)
        }
    }

    private func finishAndAdvance(final: NSRange) {
        let ended = Date()
        let event = MetricEvent(
            sessionId: sessionId,
            taskId: task.id,
            method: task.method,
            startedAt: startedAt,
            endedAt: ended,
            totalAdjustments: selectionChangeCount,
            excessTravel: max(0, selectionChangeCount > 0 ? (netDeltaChars - final.length) : 0),
            finalSelectionRange: final.location..<(final.location + final.length),
            textLength: text.count
        )
        onFinish?(event)

        // Reset metrics for next task
        startedAt = Date()
        selectionChangeCount = 0
        netDeltaChars = 0
        usedPrecisionEver = false
        hint = nil

        onAdvance?()
    }
}

// MARK: - Snapshot helper
extension UIView {
    func snapshot(of rect: CGRect, afterScreenUpdates: Bool) -> UIImage? {
        let r = self.bounds.intersection(rect)
        guard !r.isNull, r.width > 1, r.height > 1 else { return nil }
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = UIScreen.main.scale
        return UIGraphicsImageRenderer(size: r.size, format: fmt).image { ctx in
            ctx.cgContext.translateBy(x: -r.origin.x, y: -r.origin.y)
            self.drawHierarchy(in: self.bounds, afterScreenUpdates: afterScreenUpdates)
        }
    }
}
