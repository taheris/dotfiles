import Foundation

final class StubProtocol: URLProtocol {
    static var requests: [URLRequest] = []
    static var replies: [(Int, String)] = []

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.requests.append(request)
        let (status, body) = Self.replies.removeFirst()
        let response = HTTPURLResponse(url: request.url!, statusCode: status,
                                       httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@main
struct Tests {
    static func check(_ condition: Bool, _ message: String) throws {
        if !condition { throw RecordingError(message: message) }
    }

    static func main() async throws {
        let queue = AudioQueue()
        let samples = Data(repeating: 0, count: 300_000)
        queue.append(samples)
        let first = try queue.take()
        let second = try queue.take()
        try check(first.count == 256 * 1024, "Audio chunks must respect the API limit")
        try check(first + second == samples, "Queued samples must not be lost")
        try check(try queue.take().isEmpty, "Queue should drain")

        let stopped = AudioQueue()
        stopped.append(samples)
        stopped.markStopped()
        try check(stopped.isStopped, "User stop must signal capture completion")
        let stoppedFirst = try stopped.take()
        let stoppedSecond = try stopped.take()
        try check(stoppedFirst + stoppedSecond == samples, "User stop must preserve queued audio for finishing")
        try check(try stopped.take().isEmpty, "Stopped capture should drain without failing")

        let overflow = AudioQueue(limit: 4)
        overflow.append(Data(repeating: 0, count: 8))
        do {
            _ = try overflow.take()
            throw RecordingError(message: "Overflow should fail")
        } catch let error as RecordingError {
            try check(error.message.contains("backlog"), "Overflow must be reported")
        }
        let failed = AudioQueue()
        failed.fail("Capture failed")
        do {
            _ = try failed.take()
            throw RecordingError(message: "Capture failure should propagate")
        } catch let error as RecordingError {
            try check(error.message == "Capture failed", "Capture failure must be reported")
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let client = try HexClient(discovery: Discovery(port: 1234, token: "auth"), session: session)
        StubProtocol.replies = [
            (201, #"{"id":7,"ownerToken":"owner"}"#),
            (204, ""), (204, ""), (504, "timeout"),
            (200, #"{"text":"Hello from the app."}"#)
        ]
        try await client.create()
        try await client.send(Data(repeating: 0, count: 8))
        try await client.heartbeat()
        let transcript = try await client.finish()
        try check(transcript.text == "Hello from the app.", "Finish should return the transcript")
        try check(client.owner == nil, "Finished streams must release ownership")
        let requests = StubProtocol.requests
        try check(requests.map { $0.url!.path } == ["/streams", "/streams/7/audio",
                  "/streams/7/heartbeat", "/streams/7/finish", "/streams/7/finish"], "API routes or retry incorrect")
        try check(requests.allSatisfy { $0.value(forHTTPHeaderField: "Authorization") == "Bearer auth" },
                  "Every request must authenticate")
        try check(requests.dropFirst().allSatisfy { $0.value(forHTTPHeaderField: "X-Hex-Stream-Token") == "owner" },
                  "Stream requests must include ownership token")
        try check(requests[1].value(forHTTPHeaderField: "Content-Length") == "8", "Audio length missing")
        try check(requests[1].value(forHTTPHeaderField: "Content-Type") == "application/octet-stream", "Audio format incorrect")

        StubProtocol.replies = [(201, #"{"id":8,"ownerToken":"next"}"#), (204, "")]
        try await client.create()
        await client.cancel()
        try check(StubProtocol.requests.last!.url!.path == "/streams/8/cancel", "Cancel route incorrect")
        try check(client.owner == nil, "Cancel must release ownership")
        print("Hex client and audio queue tests passed")
    }
}
