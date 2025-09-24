//
//  TextViewRepresentable.swift
//  Precision Keyboard
//
//  Created by Ninad Patil on 24/09/25.
//

import SwiftUI
import UIKit

struct TextViewRepresentable: UIViewRepresentable {
    @Binding var text: String
    @Binding var selected: NSRange
    var onSelectionChanged: (NSRange) -> Void
    var onCaretRect: (CGRect, UIView?) -> Void
    var onPrecisionChange: (Bool) -> Void     // true on begin, false on end

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false                 // ✅ selection-only; no keyboard
        tv.isSelectable = true
        tv.autocorrectionType = .no
        tv.spellCheckingType = .no
        tv.smartQuotesType = .no
        tv.smartDashesType = .no
        tv.font = .systemFont(ofSize: 18, weight: .regular)
        tv.text = text
        tv.delegate = context.coordinator
        tv.backgroundColor = UIColor.secondarySystemBackground
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        tv.keyboardDismissMode = .onDrag      // harmless here; keeps things calm

        let lp = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        lp.minimumPressDuration = 0.45
        lp.cancelsTouchesInView = false       // ✅ don’t block native selection
        tv.addGestureRecognizer(lp)

        context.coordinator.textView = tv
        DispatchQueue.main.async { context.coordinator.reportCaretRect() }
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text { uiView.text = text }
        if uiView.selectedRange != selected {
            uiView.selectedRange = selected
            context.coordinator.reportCaretRect()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextViewRepresentable
        weak var textView: UITextView?

        init(_ parent: TextViewRepresentable) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.onSelectionChanged(textView.selectedRange)
            reportCaretRect()
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selected = textView.selectedRange
            parent.onSelectionChanged(textView.selectedRange)
            reportCaretRect()
        }

        func reportCaretRect() {
            guard let tv = textView else { return }
            let pos = tv.selectedTextRange?.end ?? tv.endOfDocument
            let rect = tv.caretRect(for: pos)
            parent.onCaretRect(rect, tv)
        }
        
        func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
            false
        }

        @objc func handleLongPress(_ gr: UILongPressGestureRecognizer) {
            switch gr.state {
            case .began:
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                parent.onPrecisionChange(true)
            case .ended, .cancelled, .failed:
                parent.onPrecisionChange(false)
            default: break
            }
        }
    }
}
