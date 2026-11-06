import Foundation

struct RecordingError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct HTTPFailure: LocalizedError {
    let status: Int
    let body: String
    var errorDescription: String? { "Hex HTTP \(status): \(body)" }
}

struct Discovery: Decodable {
    let port: Int
    let token: String
}

struct StreamOwner: Decodable {
    let id: Int
    let ownerToken: String
}

struct Transcript: Decodable {
    let text: String
}

final class HexClient {
    let discovery: Discovery
    let session: URLSession
    var owner: StreamOwner?

    init(discovery: Discovery, session: URLSession = .shared) throws {
        guard (1...65535).contains(discovery.port) else {
            throw RecordingError(message: "Invalid Hex API port")
        }
        self.discovery = discovery
        self.session = session
    }

    func makeRequest(_ path: String, body: Data = Data(), audio: Bool = false) -> URLRequest {
        var request = URLRequest(url: URL(string: "http://127.0.0.1:\(discovery.port)\(path)")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 130
        request.httpBody = body
        request.setValue("Bearer \(discovery.token)", forHTTPHeaderField: "Authorization")
        request.setValue(audio ? "application/octet-stream" : "application/json",
                         forHTTPHeaderField: "Content-Type")
        request.setValue(String(body.count), forHTTPHeaderField: "Content-Length")
        if let owner = owner {
            request.setValue(owner.ownerToken, forHTTPHeaderField: "X-Hex-Stream-Token")
        }
        return request
    }

    func post(_ path: String, body: Data = Data(), audio: Bool = false) async throws -> Data {
        let (data, response) = try await session.data(for: makeRequest(path, body: body, audio: audio))
        guard let response = response as? HTTPURLResponse else {
            throw RecordingError(message: "Invalid Hex API response")
        }
        guard (200..<300).contains(response.statusCode) else {
            throw HTTPFailure(status: response.statusCode, body: String(decoding: data, as: UTF8.self))
        }
        return data
    }

    func create() async throws {
        let body = Data(#"{"sampleFormat":"f32le","sampleRate":16000}"#.utf8)
        owner = try JSONDecoder().decode(StreamOwner.self, from: await post("/streams", body: body))
    }

    func path(_ action: String) throws -> String {
        guard let owner = owner else { throw RecordingError(message: "No Hex stream") }
        return "/streams/\(owner.id)/\(action)"
    }

    func send(_ audio: Data) async throws {
        _ = try await post(path("audio"), body: audio, audio: true)
    }

    func heartbeat() async throws {
        _ = try await post(path("heartbeat"))
    }

    func finish() async throws -> Transcript {
        // A 504 leaves the stream running; retry rather than losing the transcript.
        for attempt in 0..<3 {
            do {
                let result = try JSONDecoder().decode(Transcript.self, from: await post(path("finish")))
                owner = nil
                return result
            } catch let error as HTTPFailure where error.status == 504 && attempt < 2 {
                continue
            }
        }
        throw RecordingError(message: "Hex could not finish the stream")
    }

    func cancel() async {
        if let route = try? path("cancel") { _ = try? await post(route) }
        owner = nil
    }
}

// Capture callbacks must never block on network requests. Bound the queue and
// report overflow rather than silently dropping audio when transcription stalls.
final class AudioQueue {
    private let lock = NSLock()
    private var bytes = Data()
    private var failure: String?
    private var stopped = false
    private let limit: Int

    init(limit: Int = 120 * 16000 * 4) { self.limit = limit }

    var isStopped: Bool {
        lock.lock()
        defer { lock.unlock() }
        return stopped
    }

    func markStopped() {
        lock.lock()
        defer { lock.unlock() }
        stopped = true
    }

    func fail(_ message: String) {
        lock.lock()
        defer { lock.unlock() }
        failure = message
    }

    func append(_ data: Data) {
        lock.lock()
        defer { lock.unlock() }
        guard bytes.count + data.count <= limit else {
            failure = "App audio backlog exceeded 120 seconds"
            return
        }
        bytes.append(data)
    }

    func take() throws -> Data {
        lock.lock()
        defer { lock.unlock() }
        if let failure = failure { throw RecordingError(message: failure) }
        let count = min(bytes.count, 256 * 1024)
        let result = Data(bytes.prefix(count))
        bytes.removeFirst(count)
        return result
    }
}
