//
//  StudySessionStore.swift
//  Precision Keyboard
//
//  Created by Ninad Patil on 24/09/25.
//

import Foundation
import Combine

@MainActor
final class StudySessionStore: ObservableObject {
    @Published var sessionId: String = ""
    @Published var participantId: String = ""
    @Published var counterbalanceArm: Int = Int.random(in: 0...1)

    // Pangram ensures all targets exist.
    private let pangram = "The quick brown fox jumps over the lazy dog."

    // Task order: alternate standard/precision as requested
    @Published var tasks: [StudyTask] = []

    let api = APIClient()

    init() {
        APIClient.replayOutboxIfAny()
        // Default tasks (you can randomize order by counterbalanceArm if needed)
        tasks = [
            StudyTask(title: "Task 1", prompt: "Using the normal method, select the word 'quick'.",
                      initialText: pangram, target: "quick", method: .standard),
            StudyTask(title: "Task 2", prompt: "Now, using the new method, select the word 'brown'.",
                      initialText: pangram, target: "brown", method: .precision),
            StudyTask(title: "Task 3", prompt: "Using the normal method, select the phrase 'lazy dog'.",
                      initialText: pangram, target: "lazy dog", method: .standard),
            StudyTask(title: "Task 4", prompt: "Using the new method, select the phrase 'jumps over'.",
                      initialText: pangram, target: "jumps over", method: .precision),
        ]
    }

    func startSessionIfNeeded() async {
        guard sessionId.isEmpty, !participantId.isEmpty else { return }
        let req = SessionStartRequest(participantId: participantId, counterbalanceArm: counterbalanceArm, startedAt: Date())
        do {
            let resp: SessionStartResponse = try await api.post("/sessions/start", body: req, expecting: SessionStartResponse.self)
            sessionId = resp.sessionId
        } catch {
            sessionId = "local-\(UUID().uuidString)"
        }
    }

    func submitMetrics(_ m: MetricEvent) {
        api.fireAndForget("/metrics", body: m)
    }

    func submitSUS(_ submission: SUSSubmission) async throws {
        let _: Empty = try await api.post("/sus", body: submission, expecting: Empty.self)
    }
    private struct Empty: Decodable {}
}
