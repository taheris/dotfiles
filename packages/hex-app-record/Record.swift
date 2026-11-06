import AppKit
import AudioToolbox
import CoreMedia
import Darwin
import ScreenCaptureKit

final class AudioOutput: NSObject, SCStreamOutput, SCStreamDelegate {
    let audio: AudioQueue
    init(audio: AudioQueue) { self.audio = audio }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        let error = error as NSError
        if error.domain == SCStreamErrorDomain,
           error.code == SCStreamError.Code.userStopped.rawValue {
            audio.markStopped()
        } else {
            audio.fail("Capture stopped: \(error.localizedDescription)")
        }
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sample: CMSampleBuffer,
                of type: SCStreamOutputType) {
        guard type == .audio, sample.isValid,
              let description = sample.formatDescription,
              let format = CMAudioFormatDescriptionGetStreamBasicDescription(description) else { return }
        guard format.pointee.mSampleRate == 16000,
              format.pointee.mChannelsPerFrame == 1,
              format.pointee.mBitsPerChannel == 32,
              format.pointee.mFormatID == kAudioFormatLinearPCM,
              format.pointee.mFormatFlags & kAudioFormatFlagIsFloat != 0,
              format.pointee.mFormatFlags & kAudioFormatFlagIsBigEndian == 0,
              let block = sample.dataBuffer else {
            audio.fail("ScreenCaptureKit returned an unsupported audio format")
            return
        }
        let length = CMBlockBufferGetDataLength(block)
        guard length > 0 else { return }
        var bytes = Data(count: length)
        let status = bytes.withUnsafeMutableBytes {
            CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: length,
                                      destination: $0.baseAddress!)
        }
        guard status == noErr else {
            audio.fail("Could not read app audio")
            return
        }
        audio.append(bytes)
    }
}

@main
struct Recorder {
    static let home = FileManager.default.homeDirectoryForCurrentUser
    static let cache = home.appendingPathComponent("Library/Caches/hex-app-record")
    static let stop = cache.appendingPathComponent("stop")
    static let hex = URL(fileURLWithPath: "/Applications/Hex.app/Contents/MacOS/hex")

    static func exists(_ url: URL) -> Bool { FileManager.default.fileExists(atPath: url.path) }

    static func notify(_ message: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", "on run argv\ndisplay notification (item 1 of argv) with title \"Hex app audio\"\nend run", message]
        do { try process.run(); process.waitUntilExit() }
        catch { fputs("Notification failed: \(error)\n", stderr) }
    }

    static func openLock(_ name: String) throws -> Int32 {
        let fd = Darwin.open(cache.appendingPathComponent(name).path, O_CREAT | O_RDWR, 0o600)
        guard fd >= 0 else { throw RecordingError(message: "Could not open recording lock") }
        return fd
    }

    @MainActor
    static func toggle() async throws {
        // Serialize startup so two rapid presses cannot launch competing workers.
        let control = try openLock("control.lock")
        defer { close(control) }
        guard flock(control, LOCK_EX) == 0 else { throw RecordingError(message: "Could not lock toggle") }
        let lock = try openLock("record.lock")
        defer { close(lock) }
        if flock(lock, LOCK_EX | LOCK_NB) != 0 {
            guard errno == EWOULDBLOCK else { throw RecordingError(message: "Could not lock recorder") }
            try Data().write(to: stop)
            return
        }
        try? FileManager.default.removeItem(at: stop)
        _ = flock(lock, LOCK_UN)
        guard let app = NSWorkspace.shared.frontmostApplication else {
            throw RecordingError(message: "No frontmost application")
        }
        let ready = cache.appendingPathComponent("ready-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: ready) }
        let log = cache.appendingPathComponent("record.log")
        _ = FileManager.default.createFile(atPath: log.path, contents: nil)
        let output = try FileHandle(forWritingTo: log)
        defer { try? output.close() }
        let worker = Process()
        worker.executableURL = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
        worker.arguments = ["--record", String(app.processIdentifier), app.localizedName ?? "Application", ready.path]
        worker.standardInput = FileHandle.nullDevice
        worker.standardOutput = output
        worker.standardError = output
        try worker.run()
        let deadline = ProcessInfo.processInfo.systemUptime + 10
        while !exists(ready) {
            guard worker.isRunning else { throw RecordingError(message: "Recorder failed; see \(log.path)") }
            guard ProcessInfo.processInfo.systemUptime < deadline else {
                worker.terminate()
                throw RecordingError(message: "Recorder did not start; see \(log.path)")
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
    }

    static func connect() async throws -> HexClient {
        let process = Process()
        process.executableURL = hex
        process.arguments = ["start"]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw RecordingError(message: "Could not start Hex") }
        let discovery = home.appendingPathComponent("Library/Application Support/hex/local-api.json")
        let deadline = ProcessInfo.processInfo.systemUptime + 15
        while !exists(discovery) {
            guard ProcessInfo.processInfo.systemUptime < deadline else {
                throw RecordingError(message: "Hex local API did not start")
            }
            try await Task.sleep(nanoseconds: 200_000_000)
        }
        return try HexClient(discovery: JSONDecoder().decode(Discovery.self, from: Data(contentsOf: discovery)))
    }

    static func record(pid: Int32, name: String, ready: URL) async throws {
        _ = setsid()
        let lock = try openLock("record.lock")
        defer { close(lock) }
        guard flock(lock, LOCK_EX | LOCK_NB) == 0 else {
            throw RecordingError(message: "Another app recording is active")
        }
        defer {
            try? FileManager.default.removeItem(at: stop)
            try? FileManager.default.removeItem(at: ready)
        }
        try Data().write(to: ready)
        // Resolve capture permission before creating a stream with a 10-second lease.
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        guard let app = content.applications.first(where: { $0.processID == pid }),
              let display = content.displays.first else {
            throw RecordingError(message: "Selected application is not capturable")
        }
        let filter = SCContentFilter(display: display, including: [app], exceptingWindows: [])
        let config = SCStreamConfiguration()
        config.capturesAudio = true
        config.sampleRate = 16000
        config.channelCount = 1
        config.excludesCurrentProcessAudio = true
        // Subscribe only to audio: no microphone or screen images are captured.
        config.width = 2
        config.height = 2
        let audio = AudioQueue()
        let output = AudioOutput(audio: audio)
        let captureQueue = DispatchQueue(label: "hex-app-audio")
        let capture = SCStream(filter: filter, configuration: config, delegate: output)
        try capture.addStreamOutput(output, type: .audio, sampleHandlerQueue: captureQueue)
        let client = try await connect()
        try await client.create()
        do {
            try await capture.startCapture()
            notify("Transcribing \(name). Press Shift+Fn again to stop.")
            var heartbeat = ProcessInfo.processInfo.systemUptime
            while !exists(stop) && !audio.isStopped {
                let bytes = try audio.take()
                if !bytes.isEmpty {
                    try await client.send(bytes)
                    heartbeat = ProcessInfo.processInfo.systemUptime
                } else if ProcessInfo.processInfo.systemUptime - heartbeat >= 3 {
                    try await client.heartbeat()
                    heartbeat = ProcessInfo.processInfo.systemUptime
                }
                try await Task.sleep(nanoseconds: 100_000_000)
            }
            if !audio.isStopped {
                do {
                    try await capture.stopCapture()
                } catch {
                    let error = error as NSError
                    // The system Stop button can race the shortcut's stop request.
                    guard error.domain == SCStreamErrorDomain,
                          [SCStreamError.Code.userStopped.rawValue,
                           SCStreamError.Code.attemptToStopStreamState.rawValue].contains(error.code) else {
                        throw error
                    }
                }
            }
            captureQueue.sync {}
            while true {
                let bytes = try audio.take()
                if bytes.isEmpty { break }
                try await client.send(bytes)
            }
            notify("Capture stopped; finishing transcript…")
            let result = try await client.finish()
            let folder = home.appendingPathComponent("Documents/hex")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss-SSS"
            let path = folder.appendingPathComponent("\(formatter.string(from: Date()))-\(UUID().uuidString.prefix(8))-app.md")
            try "# \(name)\n\n\(result.text)\n".write(to: path, atomically: true, encoding: .utf8)
            print("Transcript saved: \(path.path)")
            notify("Transcript saved: \(path.lastPathComponent)")
        } catch {
            try? await capture.stopCapture()
            await client.cancel()
            throw error
        }
        withExtendedLifetime(output) {}
    }

    @MainActor
    static func main() async {
        umask(0o077)
        do {
            try FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
            let args = CommandLine.arguments
            if args.count == 5, args[1] == "--record", let pid = Int32(args[2]) {
                try await record(pid: pid, name: args[3], ready: URL(fileURLWithPath: args[4]))
            } else if args.count == 1 {
                try await toggle()
            } else {
                throw RecordingError(message: "Usage: hex-app-record")
            }
        } catch {
            fputs("App transcription failed: \(error.localizedDescription)\n", stderr)
            notify("Failed: \(error.localizedDescription). See ~/Library/Caches/hex-app-record/record.log")
            exit(1)
        }
    }
}
