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

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("PrecisionPointer")
        }
        .onAppear {
            // ensure clean start
            phase = .welcome
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
                    if next < session.tasks.count {
                        withAnimation { phase = .task(index: next) }
                    } else {
                        withAnimation { phase = .sus }
                    }
                }
                .environmentObject(session)
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
        VStack(alignment: .leading, spacing: 16) {
            Text("Instructions").font(.title2).bold()
            Text("""
                 You will complete a series of text selection tasks.

                 • **Standard**: Use the normal iOS selection (tap/drag handles).
                 • **Precision**: Long-press to show a full-width zoom strip; continue selecting naturally.

                 The app will automatically advance once you’ve selected the requested word or phrase. At the end, you’ll complete a short SUS questionnaire.
                 """)
                .foregroundStyle(.secondary)
            Spacer()
            Button { onBegin() } label: { Text("Begin").frame(maxWidth: .infinity) }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
