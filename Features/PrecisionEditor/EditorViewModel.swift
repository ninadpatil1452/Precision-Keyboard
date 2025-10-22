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
    
    // Enhanced metrics tracking
    private var precisionModeActivations: Int = 0
    private var precisionModeStartTime: Date?
    private var totalPrecisionDuration: TimeInterval = 0
    private var gestureCount: Int = 0
    private var longPressCount: Int = 0
    private var tapCount: Int = 0
    private var dragCount: Int = 0
    private var errorCount: Int = 0
    private var lastSelectionWasCorrect: Bool = false
    private var completionStatus: CompletionStatus = .completed

    // MARK: - Caret/Loupe
    private weak var sourceView: UIView?
    private var lastCaretRect: CGRect = .zero

    // MARK: - Callbacks
    var onAdvance: (() -> Void)?
    var onFinish: ((MetricEvent) -> Void)?
    
    // MARK: - State Management
    var hasAdvanced: Bool = false

    // MARK: - Task Context
    var task: StudyTask
    let sessionId: String

    // MARK: - Init
    init(task: StudyTask, sessionId: String) {
        self.task = task
        self.sessionId = sessionId
        self.text = task.initialText
        self.startedAt = Date()
        self.lastAnchorIndex = 0
    }
    
    // MARK: - Task Management
    func updateTask(_ newTask: StudyTask) {
        print("🔄 Updating task from '\(task.title)' to '\(newTask.title)'")
        self.task = newTask
        self.text = newTask.initialText
        self.selected = NSRange(location: 0, length: 0)
        self.startedAt = Date()
        self.lastAnchorIndex = 0
        self.hint = nil
        
        // Reset all metrics
        self.selectionChangeCount = 0
        self.netDeltaChars = 0
        self.usedPrecisionEver = false
        self.precisionModeActivations = 0
        self.totalPrecisionDuration = 0
        self.precisionModeStartTime = nil
        self.gestureCount = 0
        self.longPressCount = 0
        self.tapCount = 0
        self.dragCount = 0
        self.errorCount = 0
        self.lastSelectionWasCorrect = false
        self.completionStatus = .completed
        self.hasAdvanced = false
        
        // Reset precision mode
        self.precisionOn = false
        self.loupeImage = nil
    }

    // MARK: - Selection Tracking
    func onSelectionChanged(_ newRange: NSRange) {
        let newIndex = anchorIndex(for: newRange)
        let delta = abs(newIndex - lastAnchorIndex)
        netDeltaChars += delta
        selectionChangeCount += 1
        lastAnchorIndex = newIndex
        
        // Track selection accuracy
        let isCorrect = isExactMatch(newRange) || snapToTargetIfContained(in: newRange) != nil
        if !isCorrect && lastSelectionWasCorrect {
            errorCount += 1
        }
        lastSelectionWasCorrect = isCorrect
        
        // Debug logging for training tasks
        if task.trainingTask {
            let selectedText = newRange.location != NSNotFound && newRange.length > 0 ? 
                (text as NSString).substring(with: newRange) : ""
            print("Training Task Debug - Selected: '\(selectedText)', Target: '\(task.target)', Exact Match: \(isExactMatch(newRange))")
        }
        
        checkAutoComplete(current: newRange)
    }
    
    // MARK: - Gesture Tracking
    func recordGesture(type: GestureType) {
        gestureCount += 1
        switch type {
        case .tap: tapCount += 1
        case .longPress: longPressCount += 1
        case .drag: dragCount += 1
        }
    }
    
    enum GestureType {
        case tap, longPress, drag
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
        
        let wasOn = precisionOn
        precisionOn = on
        
        if on && !wasOn {
            // Precision mode activated
            print("🔍 Precision mode activated for task: \(task.title)")
            usedPrecisionEver = true
            precisionModeActivations += 1
            precisionModeStartTime = Date()
            refreshLoupe()
        } else if !on && wasOn {
            // Precision mode deactivated
            print("🔍 Precision mode deactivated for task: \(task.title)")
            if let startTime = precisionModeStartTime {
                totalPrecisionDuration += Date().timeIntervalSince(startTime)
                precisionModeStartTime = nil
            }
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
    func isExactMatch(_ range: NSRange) -> Bool {
        let ns = text as NSString
        guard range.location != NSNotFound, range.upperBound <= ns.length else { 
            print("❌ Invalid range: location=\(range.location), length=\(range.length), textLength=\(ns.length)")
            return false 
        }
        let sel = ns.substring(with: range)
        let isMatch = task.caseSensitive ? sel == task.target : sel.caseInsensitiveCompare(task.target) == .orderedSame
        print("🔍 Selection check: '\(sel)' vs '\(task.target)' -> \(isMatch)")
        return isMatch
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
            print("✅ Exact match found! Task: \(task.title), Method: \(task.method), Training: \(task.trainingTask)")
            // Only check for precision mode requirement if it's a precision task and not a training task
            if task.method == .precision && !usedPrecisionEver && !task.trainingTask {
                hint = "Long-press to use Precision mode for this task."
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                return
            }
            print("🚀 Calling finishAndAdvance for exact match")
            finishAndAdvance(final: current)
            return
        }
        // If user selected a bit more but only whitespace/punct around the target, snap & advance.
        if let snapped = snapToTargetIfContained(in: current) {
            print("✅ Snapped match found! Task: \(task.title)")
            // Visually correct the selection on screen
            selected = snapped
            // Only check for precision mode requirement if it's a precision task and not a training task
            if task.method == .precision && !usedPrecisionEver && !task.trainingTask {
                hint = "Long-press to use Precision mode for this task."
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                return
            }
            print("🚀 Calling finishAndAdvance for snapped match")
            finishAndAdvance(final: snapped)
        }
    }

    private func finishAndAdvance(final: NSRange) {
        print("🎯 finishAndAdvance called for task: \(task.title)")
        let ended = Date()
        
        // Finalize precision mode duration if still active
        if precisionOn, let startTime = precisionModeStartTime {
            totalPrecisionDuration += ended.timeIntervalSince(startTime)
        }
        
        // Calculate accuracy score
        let accuracyScore = calculateAccuracyScore(final: final)
        
        // Calculate average selection speed
        let totalTime = ended.timeIntervalSince(startedAt)
        let averageSelectionSpeed = totalTime > 0 ? Double(final.length) / totalTime : 0.0
        
        print("📊 Creating MetricEvent for task completion")
        let event = MetricEvent(
            sessionId: sessionId,
            taskId: task.id,
            method: task.method,
            startedAt: startedAt,
            endedAt: ended,
            totalAdjustments: selectionChangeCount,
            excessTravel: max(0, selectionChangeCount > 0 ? (netDeltaChars - final.length) : 0),
            finalSelectionRange: final.location..<(final.location + final.length),
            textLength: text.count,
            precisionModeActivations: precisionModeActivations,
            precisionModeDuration: totalPrecisionDuration,
            gestureCount: gestureCount,
            longPressCount: longPressCount,
            tapCount: tapCount,
            dragCount: dragCount,
            accuracyScore: accuracyScore,
            taskDifficulty: task.difficulty,
            taskType: task.type,
            completionStatus: completionStatus,
            errorCount: errorCount,
            averageSelectionSpeed: averageSelectionSpeed,
            cognitiveLoadScore: nil
        )
        
        print("📤 Submitting metrics (fire and forget)")
        // Submit metrics (fire and forget - don't block on this)
        onFinish?(event)
        
        // Prevent multiple advancement calls
        guard !hasAdvanced else {
            print("⚠️ Task already advanced, skipping duplicate call")
            return
        }
        hasAdvanced = true
        
        print("➡️ Calling onAdvance to move to next task")
        // Always advance the task regardless of metric submission success
        onAdvance?()

        // Reset metrics for next task
        startedAt = Date()
        selectionChangeCount = 0
        netDeltaChars = 0
        usedPrecisionEver = false
        hint = nil
        
        // Reset enhanced metrics
        precisionModeActivations = 0
        totalPrecisionDuration = 0
        precisionModeStartTime = nil
        gestureCount = 0
        longPressCount = 0
        tapCount = 0
        dragCount = 0
        errorCount = 0
        lastSelectionWasCorrect = false
        completionStatus = .completed
        hasAdvanced = false
    }
    
    // MARK: - Accuracy Calculation
    private func calculateAccuracyScore(final: NSRange) -> Double {
        guard let expectedRange = expectedRange() else { return 0.0 }
        
        // Calculate overlap between expected and actual selection
        let intersection = NSIntersectionRange(final, expectedRange)
        let overlapLength = intersection.length
        
        // Perfect match gets 1.0, partial overlap gets proportional score
        if final == expectedRange {
            return 1.0
        } else if overlapLength > 0 {
            // Calculate how much of the expected range is covered
            let expectedLength = expectedRange.length
            let coverageRatio = Double(overlapLength) / Double(expectedLength)
            
            // Penalize for selecting too much extra content
            let extraContent = max(0, final.length - expectedLength)
            let penalty = min(0.3, Double(extraContent) / Double(expectedLength) * 0.1)
            
            return max(0.0, coverageRatio - penalty)
        } else {
            return 0.0
        }
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
