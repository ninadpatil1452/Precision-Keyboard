//
//  PrecisionOverlay.swift
//  Precision Keyboard
//
//  Created by Ninad Patil on 24/09/25.
//

import SwiftUI

struct PrecisionOverlay: View {
    @ObservedObject var vm: EditorViewModel
    @State private var showAnimation = false
    @State private var magnificationScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 0) {
            // Full-screen magnified text view
            MagnifiedTextEditor(
                text: $vm.text,
                selectedRange: $vm.selected,
                onSelectionChanged: { range in
                    vm.onSelectionChanged(range)
                },
                onTapToExit: {
                    vm.togglePrecision(false)
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground).opacity(0.98),
                        Color(.secondarySystemBackground).opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // Bottom control bar
            VStack(spacing: 8) {
                // Precision controls
                HStack(spacing: 16) {
                    // Zoom level indicator
                    HStack(spacing: 4) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.blue)
                        Text("3x Magnification")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.blue.opacity(0.1))
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    // Precision mode indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                            .scaleEffect(showAnimation ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: showAnimation)
                        
                        Text("Precision Active")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.green.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                // Instruction text
                Text("Tap anywhere to exit precision mode")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
        .scaleEffect(showAnimation ? 1.0 : 0.95)
        .opacity(showAnimation ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showAnimation)
        .onAppear {
            showAnimation = true
        }
        .onDisappear {
            showAnimation = false
        }
    }
}

struct MagnifiedTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var selectedRange: NSRange
    var onSelectionChanged: (NSRange) -> Void
    var onTapToExit: () -> Void
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = UIFont.systemFont(ofSize: 32, weight: .regular) // 3x magnification
        textView.text = text
        textView.backgroundColor = UIColor.clear
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)
        textView.delegate = context.coordinator
        
        // Add tap gesture to exit precision mode
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tapGesture.cancelsTouchesInView = false
        textView.addGestureRecognizer(tapGesture)
        
        context.coordinator.textView = textView
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if uiView.selectedRange != selectedRange {
            uiView.selectedRange = selectedRange
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: MagnifiedTextEditor
        weak var textView: UITextView?
        
        init(_ parent: MagnifiedTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedRange = textView.selectedRange
            parent.onSelectionChanged(textView.selectedRange)
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            // Only exit if tapping on empty space (not on text)
            let location = gesture.location(in: textView)
            let textPosition = textView?.closestPosition(to: location)
            
            if let textPosition = textPosition,
               let textRange = textView?.textRange(from: textPosition, to: textPosition) {
                let tappedText = textView?.text(in: textRange) ?? ""
                // Exit if tapping on whitespace or empty area
                if tappedText.isEmpty || tappedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    parent.onTapToExit()
                }
            } else {
                // Exit if tapping outside text bounds
                parent.onTapToExit()
            }
        }
    }
}

struct MagnifiedTextView: View {
    let text: String
    let selectedRange: NSRange
    let magnificationScale: CGFloat
    
    var body: some View {
        let attributedString = createAttributedString()
        
        Text(AttributedString(attributedString))
            .font(.system(size: 24, weight: .regular, design: .default))
            .lineSpacing(8)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func createAttributedString() -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        
        // Set default attributes
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .regular),
            .foregroundColor: UIColor.label
        ]
        attributedString.addAttributes(defaultAttributes, range: NSRange(location: 0, length: text.count))
        
        // Highlight selected range
        if selectedRange.location != NSNotFound && selectedRange.length > 0 {
            let selectionAttributes: [NSAttributedString.Key: Any] = [
                .backgroundColor: UIColor.systemBlue.withAlphaComponent(0.3),
                .foregroundColor: UIColor.label
            ]
            attributedString.addAttributes(selectionAttributes, range: selectedRange)
        }
        
        return attributedString
    }
}
