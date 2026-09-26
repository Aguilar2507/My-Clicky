import Foundation

/// The app side of `agent.sock` (spec 009): a Unix-domain socket only this user can open (mode 0600).
/// Each connection carries one request line and gets one response line. Lives in Core so checks can run
/// a real round trip with the `MyClickyComputer` bridge.
public final class BridgeSocketServer: @unchecked Sendable {
    public typealias Handler = @Sendable (BridgeRequest) async -> BridgeResponse

    public let path: String
    private let handler: Handler
    private var listenFD: Int32 = -1
    private var acceptSource: DispatchSourceRead?
    private let queue = DispatchQueue(label: "MyClicky.BridgeSocketServer", attributes: .concurrent)

    public init(path: String, handler: @escaping Handler) {
        self.path = path
        self.handler = handler
    }

    public enum ServerError: Error { case socket, bind(Int32), listen }

    public func start() throws {
        stop()
        unlink(path)
        try FileManager.default.createDirectory(atPath: (path as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { throw ServerError.socket }
        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        let bytes = Array(path.utf8)
        guard bytes.count < MemoryLayout.size(ofValue: address.sun_path) else { close(fd); throw ServerError.bind(ENAMETOOLONG) }
        withUnsafeMutableBytes(of: &address.sun_path) { buffer in
            buffer.copyBytes(from: bytes)
            buffer[bytes.count] = 0
        }
        let bound = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) }
        }
        guard bound == 0 else { close(fd); throw ServerError.bind(errno) }
        chmod(path, 0o600)
        guard listen(fd, 16) == 0 else { close(fd); throw ServerError.listen }
        listenFD = fd
        let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: queue)
        source.setEventHandler { [weak self] in self?.acceptOne() }
        source.resume()
        acceptSource = source
    }

    public func stop() {
        acceptSource?.cancel()
        acceptSource = nil
        if listenFD >= 0 { close(listenFD) }
        listenFD = -1
        unlink(path)
    }

    private func acceptOne() {
        let client = accept(listenFD, nil, nil)
        guard client >= 0 else { return }
        queue.async { [weak self] in self?.serve(client) }
    }

    private func serve(_ client: Int32) {
        var received = Data()
        var byte: UInt8 = 0
        while read(client, &byte, 1) == 1 {
            if byte == 0x0A { break }
            received.append(byte)
        }
        guard let request = try? JSONFile.decoder.decode(BridgeRequest.self, from: received) else {
            close(client)
            return
        }
        let handler = self.handler
        Task {
            let response = await handler(request)
            var line = (try? JSONFile.encoder.encode(response)).map { Data(String(decoding: $0, as: UTF8.self)
                .replacingOccurrences(of: "\n", with: " ").utf8) } ?? Data("{}".utf8)
            line.append(0x0A)
            _ = line.withUnsafeBytes { write(client, $0.baseAddress, line.count) }
            close(client)
        }
    }
}
