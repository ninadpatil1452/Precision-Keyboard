//
//  RunTaskView.swift
//  Precision Keyboard
//
//  Created by Ninad Patil on 24/09/25.
//

import SwiftUI

struct RunTaskView: View {
    @EnvironmentObject var session: StudySessionStore
    let task: StudyTask
    let sessionId: String
    var onDone: () -> Void
    
    @StateObject private var vm: EditorViewModel
    @State private var currentTaskIndex: Int = 0
    @State private var showProgress = true

    init(task: StudyTask, sessionId: String, onDone: @escaping () -> Void) {
        self.task = task
        self.sessionId = sessionId
        self.onDone = onDone
        self._vm = StateObject(wrappedValue: EditorViewModel(task: task, sessionId: sessionId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Enhanced header with progress and task info
            VStack(spacing: 12) {
                // Progress indicator
                if showProgress {
                    ProgressIndicatorView(
                        currentIndex: currentTaskIndex,
                        totalTasks: session.tasks.count,
                        isTrainingTask: task.trainingTask
                    )
                }
                
                // Task information
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(task.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        // Task difficulty and type badges
                        HStack(spacing: 8) {
                            DifficultyBadge(difficulty: task.difficulty)
                            TaskTypeBadge(type: task.type)
                            MethodBadge(method: task.method)
                        }
                    }
                    
                    Text(task.prompt)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    if let hint = vm.hint {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.orange)
                            Text(hint)
                                .font(.footnote)
                                .foregroundStyle(.orange)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.orange.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding()

            Divider()

            // Enhanced text view with better visual feedback
            ZStack {
                TextViewRepresentable(
                    text: $vm.text,
                    selected: $vm.selected,
                    onSelectionChanged: { r in vm.onSelectionChanged(r) },
                    onCaretRect: { rect, view in vm.setCaretRect(rect, sourceView: view) },
                    onPrecisionChange: { on in
                        if vm.task.method == .precision {
                            vm.togglePrecision(on)
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Selection feedback overlay
                if vm.selected.length > 0 {
                    let selectedText = String(vm.text[vm.text.index(vm.text.startIndex, offsetBy: vm.selected.location)...vm.text.index(vm.text.startIndex, offsetBy: vm.selected.location + vm.selected.length - 1)])
                    let isCorrect = vm.isExactMatch(vm.selected)
                    
                    SelectionFeedbackOverlay(
                        selectedText: selectedText,
                        targetText: task.target,
                        isCorrect: isCorrect,
                        showAdvanceHint: task.trainingTask && isCorrect
                    )
                }
            }
            .overlay {
                if vm.precisionOn { 
                    PrecisionOverlay(vm: vm)
                        .transition(.opacity.combined(with: .scale))
                        .zIndex(1000) // Ensure it's on top
                }
            }
            .overlay(alignment: .topTrailing) {
                // Manual advance button for training tasks
                if task.trainingTask && vm.selected.length > 0 && vm.isExactMatch(vm.selected) {
                    Button(action: {
                        print("🔘 Manual Next button tapped")
                        // Call onAdvance directly to bypass the hasAdvanced guard
                        onDone()
                    }) {
                        HStack(spacing: 4) {
                            Text("Next")
                            Image(systemName: "arrow.right")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .shadow(radius: 2)
                    }
                    .padding(.top, 60)
                    .padding(.trailing, 16)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onAppear {
            vm.onFinish = { metric in 
                print("📊 Metrics received in RunTaskView, submitting...")
                session.submitMetrics(metric) 
            }
            vm.onAdvance = { 
                print("➡️ onAdvance called in RunTaskView, calling onDone()")
                onDone() 
            }
            
            // Find current task index for progress tracking
            currentTaskIndex = session.tasks.firstIndex { $0.id == task.id } ?? 0
            print("🎯 RunTaskView appeared for task: \(task.title) (index: \(currentTaskIndex), taskId: \(task.id))")
        }
        .onChange(of: task.id) { oldValue, newValue in
            print("🔄 Task ID changed from \(oldValue) to \(newValue)")
            // Update the view model with the new task
            vm.updateTask(task)
        }
    }
}

// MARK: - Supporting Views

struct ProgressIndicatorView: View {
    let currentIndex: Int
    let totalTasks: Int
    let isTrainingTask: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(isTrainingTask ? "Training Session" : "Study Task")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(currentIndex + 1) of \(totalTasks)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            
            ProgressView(value: Double(currentIndex), total: Double(totalTasks - 1))
                .progressViewStyle(LinearProgressViewStyle(tint: isTrainingTask ? .blue : .green))
                .scaleEffect(y: 2)
        }
    }
}

struct DifficultyBadge: View {
    let difficulty: TaskDifficulty
    
    var body: some View {
        Text(difficulty.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(difficultyColor.opacity(0.2))
            .foregroundStyle(difficultyColor)
            .clipShape(Capsule())
    }
    
    private var difficultyColor: Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

struct TaskTypeBadge: View {
    let type: TaskType
    
    var body: some View {
        Text(type.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.blue.opacity(0.2))
            .foregroundStyle(.blue)
            .clipShape(Capsule())
    }
}

struct MethodBadge: View {
    let method: MethodKind
    
    var body: some View {
        Text(method.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(methodColor.opacity(0.2))
            .foregroundStyle(methodColor)
            .clipShape(Capsule())
    }
    
    private var methodColor: Color {
        switch method {
        case .standard: return .gray
        case .precision: return .purple
        }
    }
}

struct SelectionFeedbackOverlay: View {
    let selectedText: String
    let targetText: String
    let isCorrect: Bool
    let showAdvanceHint: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(isCorrect ? .green : .orange)
                        
                        Text(isCorrect ? "Correct!" : "Keep trying")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(isCorrect ? .green : .orange)
                    }
                    
                    Text("Selected: \"\(selectedText)\"")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if showAdvanceHint {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Task will advance automatically...")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.blue)
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(radius: 4)
                
                Spacer()
            }
            .padding(.bottom, 20)
        }
        .animation(.easeInOut(duration: 0.3), value: isCorrect)
        .animation(.easeInOut(duration: 0.3), value: showAdvanceHint)
    }
}
