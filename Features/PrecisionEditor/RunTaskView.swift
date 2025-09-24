//
//  RunTaskView.swift
//  Precision Keyboard
//
//  Created by Ninad Patil on 24/09/25.
//

import SwiftUI

struct RunTaskView: View {
    @EnvironmentObject var session: StudySessionStore
    @StateObject var vm: EditorViewModel
    var onDone: () -> Void

    init(task: StudyTask, sessionId: String, onDone: @escaping () -> Void) {
        _vm = StateObject(wrappedValue: EditorViewModel(task: task, sessionId: sessionId))
        self.onDone = onDone
    }

    var body: some View {
        VStack(spacing: 0) {
            // Prompt
            VStack(alignment: .leading, spacing: 6) {
                Text(vm.task.title).font(.headline)
                Text(vm.task.prompt).font(.subheadline).foregroundStyle(.secondary)
                if let hint = vm.hint {
                    Text(hint).font(.footnote).foregroundStyle(.orange)
                }
            }
            .padding()

            Divider()

            // Natural selection text view
            TextViewRepresentable(
                text: $vm.text,
                selected: $vm.selected,
                onSelectionChanged: { r in vm.onSelectionChanged(r) },
                onCaretRect: { rect, view in vm.setCaretRect(rect, sourceView: view) },
                onPrecisionChange: { on in
                    // ⛔️ No precision overlay for standard tasks
                    if vm.task.method == .precision {
                        vm.togglePrecision(on)
                    }
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                if vm.precisionOn { PrecisionOverlay(vm: vm).transition(.move(edge: .bottom).combined(with: .opacity)) }
            }
        }
        .onAppear {
            vm.onFinish = { metric in session.submitMetrics(metric) }
            vm.onAdvance = { onDone() }
        }
    }
}
