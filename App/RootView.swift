//
//  ContentView.swift
//  Precision Keyboard
//
//  Created by Ninad Patil on 08/09/25.
//

import SwiftUI

private enum Phase {
    case welcome, instructions, task(index: Int), sus, done
}

struct RootView: View {
    @EnvironmentObject var session: StudySessionStore
    @State private var phase: Phase = .welcome
    @State private var consentGiven = false
    @State private var enteredId: String = ""
    
    // Debug state tracking
    @State private var debugTaskIndex: Int = -1

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Debug indicator
                if case .task(let i) = phase {
                    HStack {
                        Text("Debug: Task \(i) of \(session.tasks.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Phase: \(debugTaskIndex)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        // Temporary manual advance button for testing
                        Button("Skip") {
                            let next = i + 1
                            if next < session.tasks.count {
                                withAnimation { phase = .task(index: next) }
                            } else {
                                withAnimation { phase = .sus }
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                }
                
                content
            }
            .navigationTitle("PrecisionPointer")
        }
        .onAppear {
            // ensure clean start
            phase = .welcome
            print("📋 Available tasks: \(session.tasks.map { "\($0.title): \($0.target)" })")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .welcome:
            WelcomeView(participantId: $enteredId, consentGiven: $consentGiven) {
                session.participantId = enteredId.trimmingCharacters(in: .whitespacesAndNewlines)
                Task { await session.startSessionIfNeeded() }
                withAnimation { phase = .instructions }
            }
        case .instructions:
            InstructionsView {
                withAnimation { phase = .task(index: 0) }
            }
        case .task(let i):
            RunTaskView(task: session.tasks[i], sessionId: session.sessionId) {
                    let next = i + 1
                    print("🔄 Task \(i) completed, moving to task \(next) of \(session.tasks.count)")
                    if next < session.tasks.count {
                        print("➡️ Advancing to next task: \(session.tasks[next].title)")
                        debugTaskIndex = next
                        withAnimation(.easeInOut(duration: 0.5)) { 
                            phase = .task(index: next) 
                        }
                    } else {
                        print("🏁 All tasks completed, moving to SUS survey")
                        withAnimation(.easeInOut(duration: 0.5)) { 
                            phase = .sus 
                        }
                    }
                }
                .environmentObject(session)
                .id("task-\(i)") // Force view recreation when task index changes
                .onAppear {
                    debugTaskIndex = i
                    print("🎯 RunTaskView appeared for task index: \(i), title: \(session.tasks[i].title)")
                }
        case .sus:
            SUSView {
                withAnimation { phase = .done }
            }
            .environmentObject(session)
        case .done:
            CompletionView()
        }
    }
}

struct WelcomeView: View {
    @Binding var participantId: String
    @Binding var consentGiven: Bool
    var onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Welcome").font(.title2).bold()
            Text("Please enter your participant ID (e.g., “Participant01”). Your interaction data (timings, selections, SUS responses) will be stored without personally identifying information and used only for this study.")
                .foregroundStyle(.secondary)

            TextField("Participant ID", text: $participantId)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(10)
                .background(Color.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Toggle("I consent to participate and for my anonymized data to be used for research purposes.", isOn: $consentGiven)
                .toggleStyle(.switch)

            Spacer()

            Button {
                onContinue()
            } label: { Text("Continue").frame(maxWidth: .infinity) }
            .buttonStyle(.borderedProminent)
            .disabled(participantId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !consentGiven)
        }
        .padding()
    }
}

struct InstructionsView: View {
    var onBegin: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Study Instructions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                VStack(alignment: .leading, spacing: 16) {
                    InstructionSection(
                        title: "What You'll Do",
                        content: "You will complete a series of text selection tasks using two different methods. The study includes both training tasks and main study tasks.",
                        icon: "target"
                    )
                    
                    InstructionSection(
                        title: "Standard Selection Method",
                        content: "Use the normal iOS text selection method - tap and drag the selection handles to highlight text.",
                        icon: "hand.tap"
                    )
                    
                    InstructionSection(
                        title: "Precision Mode Method", 
                        content: "Long-press anywhere in the text area to activate precision mode. This will show a magnified view of the text with enhanced selection capabilities.",
                        icon: "magnifyingglass"
                    )
                    
                    InstructionSection(
                        title: "Task Types",
                        content: "You'll be asked to select single words, phrases, and sentences of varying difficulty levels. The app will automatically advance once you've correctly selected the requested text.",
                        icon: "text.cursor"
                    )
                    
                    InstructionSection(
                        title: "Survey",
                        content: "At the end of all tasks, you'll complete a brief System Usability Scale (SUS) questionnaire about your experience with both methods.",
                        icon: "checkmark.circle"
                    )
                }
                
                Spacer(minLength: 20)
                
                Button { 
                    onBegin() 
                } label: { 
                    HStack {
                        Text("Begin Study")
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
    }
}

struct InstructionSection: View {
    let title: String
    let content: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}
