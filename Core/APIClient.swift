//
//  APIClient.swift
//  Precision Keyboard
//
//  Created by Ninad Patil on 24/09/25.
//

import Foundation

final class APIClient {
    // TODO: set your Go backend URL
    private let baseURL = URL(string: "http://localhost:8080")!

    private let json = JSONDecoder()
    private let enc = JSONEncoder()

    init() {
        json.dateDecodingStrategy = .iso8601
        enc.dateEncodingStrategy = .iso8601
    }

    func post<T: Encodable, U: Decodable>(_ path: String, body: T, expecting: U.Type) async throws -> U {
        guard let url = URL(string: path, relativeTo: baseURL) else { throw APIError.badURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do { req.httpBody = try enc.encode(body) } catch { throw APIError.encoding }

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else { throw APIError.unknown }
            guard (200..<300).contains(http.statusCode) else { throw APIError.badStatus(http.statusCode) }
            do { return try json.decode(U.self, from: data) } catch { throw APIError.decoding }
        } catch {
            if let e = error as? APIError { throw e }
            throw APIError.network(error)
        }
    }

    func fireAndForget<T: Encodable>(_ path: String, body: T) {
        Task.detached {
            do {
                let _: EmptyResponse = try await self.post(path, body: body, expecting: EmptyResponse.self)
            } catch {
                // Minimal retry (3 attempts with backoff)
                for i in 1...3 {
                    try await Task.sleep(nanoseconds: UInt64(0.5 * pow(2.0, Double(i)) * 1_000_000_000))
                    do {
                        let _: EmptyResponse = try await self.post(path, body: body, expecting: EmptyResponse.self)
                        return
                    } catch { continue }
                }
                // If still failing, write to an outbox for later (simple persistence)
                do {
                    let url = try Self.outboxURL()
                    let envelope = OutboxEnvelope(path: path, data: try self.enc.encode(body))
                    var arr = (try? Data(contentsOf: url)).flatMap { try? JSONDecoder().decode([OutboxEnvelope].self, from: $0) } ?? []
                    arr.append(envelope)
                    let data = try JSONEncoder().encode(arr)
                    try data.write(to: url, options: .atomic)
                } catch { /* swallow */ }
            }
        }
    }

    static func replayOutboxIfAny() {
        Task.detached {
            guard let baseURL = URL(string: "http://localhost:8080") else { return }
            let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
            let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
            do {
                let url = try outboxURL()
                guard let data = try? Data(contentsOf: url) else { return }
                var arr = (try? dec.decode([OutboxEnvelope].self, from: data)) ?? []
                guard !arr.isEmpty else { return }
                var remaining: [OutboxEnvelope] = []
                for env in arr {
                    guard let full = URL(string: env.path, relativeTo: baseURL) else { continue }
                    var req = URLRequest(url: full)
                    req.httpMethod = "POST"
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    req.httpBody = env.data
                    do {
                        let (_, resp) = try await URLSession.shared.data(for: req)
                        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                            remaining.append(env); continue
                        }
                    } catch { remaining.append(env) }
                }
                let newData = try enc.encode(remaining)
                try newData.write(to: url, options: .atomic)
            } catch { /* ignore */ }
        }
    }

    private struct EmptyResponse: Decodable {}
    private struct OutboxEnvelope: Codable { let path: String; let data: Data }
    private static func outboxURL() throws -> URL {
        let dir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return dir.appendingPathComponent("metrics_outbox.json")
    }
}
