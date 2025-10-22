//
//  Models.swift
//  Precision Keyboard
//
//  Created by Ninad Patil on 24/09/25.
//

import Foundation

enum MethodKind: String, Codable, CaseIterable { 
    case standard, precision 
    
    var displayName: String {
        switch self {
        case .standard: return "Standard Selection"
        case .precision: return "Precision Mode"
        }
    }
}

enum TaskDifficulty: String, Codable, CaseIterable {
    case easy, medium, hard
    
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium" 
        case .hard: return "Hard"
        }
    }
}

enum TaskType: String, Codable, CaseIterable {
    case singleWord, phrase, sentence, paragraph
    
    var displayName: String {
        switch self {
        case .singleWord: return "Single Word"
        case .phrase: return "Phrase"
        case .sentence: return "Sentence"
        case .paragraph: return "Paragraph"
        }
    }
}

enum AnchorSide: String, Codable, CaseIterable { case caret, start, end }

struct StudyTask: Identifiable, Codable, Hashable {
    var id: UUID = .init()
    var title: String
    var prompt: String
    var initialText: String
    var target: String              // text to be selected
    var method: MethodKind          // expected method
    var difficulty: TaskDifficulty = .medium
    var type: TaskType = .singleWord
    var caseSensitive: Bool = false
    var timeLimit: TimeInterval? = nil  // Optional time limit in seconds
    var trainingTask: Bool = false     // Whether this is a training task
}

struct SessionStartRequest: Codable {
    let participantId: String
    let counterbalanceArm: Int
    let startedAt: Date
}

struct SessionStartResponse: Codable { let sessionId: String }

struct MetricEvent: Codable, Identifiable {
    var id: UUID = .init()
    let sessionId: String
    let taskId: UUID
    let method: MethodKind          // task's intended method
    let startedAt: Date
    let endedAt: Date
    let totalAdjustments: Int       // #selection changes
    let excessTravel: Int           // best-effort char distance over net
    let finalSelectionRange: Range<Int>
    let textLength: Int
    
    // Enhanced metrics
    let precisionModeActivations: Int    // How many times precision mode was activated
    let precisionModeDuration: TimeInterval  // Total time spent in precision mode
    let gestureCount: Int              // Number of gestures performed
    let longPressCount: Int            // Number of long presses
    let tapCount: Int                  // Number of taps
    let dragCount: Int                 // Number of drag gestures
    let accuracyScore: Double          // 0.0 to 1.0 based on selection accuracy
    let taskDifficulty: TaskDifficulty
    let taskType: TaskType
    let completionStatus: CompletionStatus
    let errorCount: Int                // Number of selection errors/corrections
    let averageSelectionSpeed: Double  // Characters selected per second
    let cognitiveLoadScore: Double?    // Optional subjective cognitive load (1-5)
}

enum CompletionStatus: String, Codable {
    case completed, timeout, abandoned, error
}

struct SUSSubmission: Codable {
    let sessionId: String
    let responses: [Int]
    let submittedAt: Date
}

enum APIError: Error, LocalizedError {
    case badURL, badStatus(Int), decoding, encoding, network(Error), unknown
    var errorDescription: String? {
        switch self {
        case .badURL: return "Invalid URL."
        case .badStatus(let c): return "Server returned \(c)."
        case .decoding: return "Decode failed."
        case .encoding: return "Encode failed."
        case .network(let e): return "Network error: \(e.localizedDescription)"
        case .unknown: return "Unknown error."
        }
    }
}
