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
        setupTasks()
    }
    
    private func setupTasks() {
        // Training tasks first
        let trainingTasks = createTrainingTasks()
        
        // Main study tasks with diverse content
        let studyTasks = createStudyTasks()
        
        // Combine and randomize based on counterbalance
        var allTasks = trainingTasks + studyTasks
        
        // Apply counterbalancing for method order
        if counterbalanceArm == 1 {
            // Reverse the order of methods for half the participants
            for i in stride(from: trainingTasks.count, to: allTasks.count, by: 2) {
                if i + 1 < allTasks.count {
                    allTasks.swapAt(i, i + 1)
                }
            }
        }
        
        tasks = allTasks
    }
    
    private func createTrainingTasks() -> [StudyTask] {
        return [
            StudyTask(
                title: "Training 1", 
                prompt: "Practice with standard selection. Select the word 'practice'.",
                initialText: "This is a practice session to help you get familiar with the interface.",
                target: "practice",
                method: .standard,
                difficulty: .easy,
                type: .singleWord,
                trainingTask: true
            ),
            StudyTask(
                title: "Training 2",
                prompt: "Now try precision mode. Long-press to activate, then select 'precision'.",
                initialText: "Precision mode provides magnified text for accurate selection.",
                target: "precision",
                method: .precision,
                difficulty: .easy,
                type: .singleWord,
                trainingTask: true
            )
        ]
    }
    
    private func createStudyTasks() -> [StudyTask] {
        let textContent = [
            "The quick brown fox jumps over the lazy dog. This pangram contains every letter of the alphabet at least once.",
            "Precision text selection on mobile devices remains a challenging interaction paradigm that requires careful design consideration and user testing.",
            "Mobile computing has revolutionized how we interact with digital content, but text manipulation on small screens continues to present unique usability challenges.",
            "Human-computer interaction research has shown that gesture-based interfaces can significantly improve user experience when properly implemented and tested."
        ]
        
        let targets = [
            ["quick", "brown", "jumps over", "lazy dog"],
            ["Precision", "mobile devices", "interaction paradigm", "user testing"],
            ["Mobile computing", "digital content", "small screens", "usability challenges"],
            ["Human-computer interaction", "gesture-based interfaces", "user experience", "properly implemented"]
        ]
        
        var tasks: [StudyTask] = []
        let difficulties: [TaskDifficulty] = [.easy, .medium, .hard, .medium]
        let types: [TaskType] = [.singleWord, .singleWord, .phrase, .sentence]
        
        for (textIndex, text) in textContent.enumerated() {
            let textTargets = targets[textIndex]
            let difficulty = difficulties[textIndex]
            let type = types[textIndex]
            
            for (targetIndex, target) in textTargets.enumerated() {
                let method: MethodKind = targetIndex % 2 == 0 ? .standard : .precision
                let taskNumber = textIndex * 4 + targetIndex + 1
                
                tasks.append(StudyTask(
                    title: "Task \(taskNumber)",
                    prompt: "Using \(method.displayName.lowercased()), select: '\(target)'",
                    initialText: text,
                    target: target,
                    method: method,
                    difficulty: difficulty,
                    type: type,
                    timeLimit: difficulty == .hard ? 30 : nil
                ))
            }
        }
        
        return tasks
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
