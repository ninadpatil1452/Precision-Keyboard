//
//  SUSView.swift
//  Precision Keyboard
//
//  Created by Ninad Patil on 24/09/25.
//

import SwiftUI

private let susItems: [String] = [
    "I think that I would like to use this system frequently.",
    "I found the system unnecessarily complex.",
    "I thought the system was easy to use.",
    "I think that I would need the support of a technical person to use this system.",
    "I found the various functions in this system were well integrated.",
    "I thought there was too much inconsistency in this system.",
    "I would imagine that most people would learn to use this system very quickly.",
    "I found the system very cumbersome to use.",
    "I felt very confident using the system.",
    "I needed to learn a lot of things before I could get going with this system."
]

struct SUSView: View {
    @EnvironmentObject var session: StudySessionStore
    var onSubmitted: () -> Void = {}

    @State private var answers = Array(repeating: 3, count: 10)
    @State private var busy = false
    @State private var status: String?

    var body: some View {
        Form {
            Section(header: Text("System Usability Scale (1 = Strongly Disagree, 5 = Strongly Agree)")) {
                ForEach(susItems.indices, id: \.self) { i in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(susItems[i]).font(.subheadline)
                        Picker("Response", selection: $answers[i]) {
                            ForEach(1...5, id: \.self) { v in
                                Text("\(v)").tag(v)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 2)
                }
            }

            Section {
                Button(action: {
                    Task { await submit() }
                }) {
                    if busy {
                        ProgressView()
                    } else {
                        Text("Submit SUS")
                    }
                }
                .disabled(busy)

                // Avoid shorthand optional binding inside ViewBuilder
                if let s = status {
                    Text(s)
                }
            }
        }
        .navigationTitle("SUS Survey")
    }

    private func submit() async {
        busy = true
        defer { busy = false }
        let req = SUSSubmission(sessionId: session.sessionId, responses: answers, submittedAt: Date())
        do {
            try await session.submitSUS(req)
            status = "Submitted!"
            onSubmitted()
        } catch {
            status = error.localizedDescription
        }
    }
}
