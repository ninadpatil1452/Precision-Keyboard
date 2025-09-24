//
//  Models.swift
//  Precision Keyboard
//
//  Created by Ninad Patil on 24/09/25.
//

import Foundation

enum MethodKind: String, Codable { case standard, precision }
enum AnchorSide: String, Codable, CaseIterable { case caret, start, end }

struct StudyTask: Identifiable, Codable, Hashable {
    var id: UUID = .init()
    var title: String
    var prompt: String
    var initialText: String
    var target: String              // text to be selected
    var method: MethodKind          // expected method
    var caseSensitive: Bool = false
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
    let method: MethodKind          // task’s intended method
    let startedAt: Date
    let endedAt: Date
    let totalAdjustments: Int       // #selection changes
    let excessTravel: Int           // best-effort char distance over net
    let finalSelectionRange: Range<Int>
    let textLength: Int
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
