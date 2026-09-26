import Foundation
import MyClickyCore

// MyClickyComputer: a tiny MCP stdio server (spec 009, contracts/agent-bridge.md).
// Claude Code starts it for each Clicky run. It has no permissions of its own: every tool call is forwarded over
// ~/Library/Application Support/MyClicky/agent.sock to the MyClicky app, which asks the user (Allow cards) and
// performs screenshots/clicks/typing with the app's permissions.

setvbuf(stdout, nil, _IOLBF, 0)

func argument(_ name: String) -> String? {
    guard let index = CommandLine.arguments.firstIndex(of: name), index + 1 < CommandLine.arguments.count else { return nil }
    return CommandLine.arguments[index + 1]
}

let chatID = argument("--chat") ?? ""
let socketPath = argument("--socket") ?? AppPaths.standard.agentSocket.path

/// Sends one request line to the app and waits for one response line (approvals can take minutes).
func forward(_ request: BridgeRequest) -> BridgeResponse {
    let failure = { (message: String) in BridgeResponse(id: request.id, ok: false, content: [.text(message)], error: message) }
    let fd = socket(AF_UNIX, SOCK_STREAM, 0)
    guard fd >= 0 else { return failure("MyClicky bridge: socket failed") }
    defer { close(fd) }
    var address = sockaddr_un()
    address.sun_family = sa_family_t(AF_UNIX)
    let pathBytes = Array(socketPath.utf8)
    guard pathBytes.count < MemoryLayout.size(ofValue: address.sun_path) else { return failure("Socket path too long") }
    withUnsafeMutableBytes(of: &address.sun_path) { buffer in
        buffer.copyBytes(from: pathBytes)
        buffer[pathBytes.count] = 0
    }
    let connected = withUnsafePointer(to: &address) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) }
    }
    guard connected == 0 else { return failure("MyClicky isn't running, so this action isn't available.") }
    var timeout = timeval(tv_sec: 11 * 60, tv_usec: 0) // approvals wait up to 10 minutes
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))

    guard var line = try? JSONFile.encoder.encode(request) else { return failure("Couldn't encode request") }
    line = Data(String(decoding: line, as: UTF8.self).replacingOccurrences(of: "\n", with: " ").utf8)
    line.append(0x0A)
    _ = line.withUnsafeBytes { write(fd, $0.baseAddress, line.count) }

    var received = Data()
    var byte: UInt8 = 0
    while read(fd, &byte, 1) == 1 {
        if byte == 0x0A { break }
        received.append(byte)
    }
    guard let response = try? JSONFile.decoder.decode(BridgeResponse.self, from: received) else {
        return failure("No answer from MyClicky")
    }
    return response
}

func mcpContent(_ response: BridgeResponse) -> [[String: Any]] {
    response.content.map { item in
        if item.type == "image", let data = item.data {
            return ["type": "image", "data": data, "mimeType": item.mimeType ?? "image/jpeg"]
        }
        return ["type": "text", "text": item.text ?? ""]
    }
}

var counter = 0
while let line = readLine() {
    guard let message = MCPProtocol.parse(line: line) else { continue }
    switch message.method {
    case "initialize":
        let version = message.params["protocolVersion"] as? String ?? MCPProtocol.protocolVersion
        print(MCPProtocol.result(id: message.id, ["protocolVersion": version, "capabilities": ["tools": [String: Any]()],
                                                  "serverInfo": ["name": "myclicky", "version": "1.0"]]))
    case "tools/list":
        print(MCPProtocol.result(id: message.id, ["tools": MCPProtocol.tools]))
    case "tools/call":
        counter += 1
        let name = message.params["name"] as? String ?? ""
        let arguments = (message.params["arguments"] as? [String: Any] ?? [:]).mapValues(JSONValue.init(any:))
        let response = forward(BridgeRequest(id: "\(ProcessInfo.processInfo.processIdentifier)-\(counter)", chatID: chatID,
                                             tool: name, input: arguments))
        print(MCPProtocol.result(id: message.id, ["content": mcpContent(response), "isError": !response.ok]))
    case "ping":
        print(MCPProtocol.result(id: message.id, [:]))
    default:
        if message.id != nil { print(MCPProtocol.error(id: message.id, code: -32601, message: "Unknown method \(message.method)")) }
    }
}
