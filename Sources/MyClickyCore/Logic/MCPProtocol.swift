import Foundation

/// JSON-RPC 2.0 over newline-delimited JSON, as used by MCP stdio servers (spec 009 contracts/agent-bridge.md).
/// Shared by the `MyClickyComputer` bridge and the app's socket server.
public enum MCPProtocol {
    public static let protocolVersion = "2025-06-18"

    /// A request or notification. `id` is nil for notifications. Numbers and strings are both valid ids.
    public struct Incoming {
        public let id: Any?
        public let method: String
        public let params: [String: Any]
    }

    public static func parse(line: String) -> Incoming? {
        guard let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let method = json["method"] as? String else { return nil }
        return Incoming(id: json["id"], method: method, params: json["params"] as? [String: Any] ?? [:])
    }

    public static func result(id: Any?, _ result: [String: Any]) -> String {
        encode(["jsonrpc": "2.0", "id": id ?? NSNull(), "result": result])
    }

    public static func error(id: Any?, code: Int, message: String) -> String {
        encode(["jsonrpc": "2.0", "id": id ?? NSNull(), "error": ["code": code, "message": message]])
    }

    public static func encode(_ object: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]),
              let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }

    /// The MyClicky tools (approve + computer use).
    public static let tools: [[String: Any]] = [
        tool("approve", "Ask the user to allow a tool call.", ["tool_name": "string", "input": "object"], required: ["tool_name", "input"]),
        tool("screenshot", "Take a screenshot of one of the user's screens (1-based screen number, default 1).", ["screen": "integer"]),
        tool("click", "Click at x,y in screenshot pixels on a screen.", ["x": "number", "y": "number", "button": "string",
                                                                         "count": "integer", "screen": "integer"], required: ["x", "y"]),
        tool("type", "Type text at the current focus.", ["text": "string"], required: ["text"]),
        tool("key", "Press a key combination like cmd+space or return.", ["combo": "string"], required: ["combo"]),
        tool("scroll", "Scroll by dx,dy lines.", ["dx": "integer", "dy": "integer"], required: ["dx", "dy"]),
        tool("move", "Move the pointer to x,y in screenshot pixels.", ["x": "number", "y": "number", "screen": "integer"], required: ["x", "y"]),
    ]

    private static func tool(_ name: String, _ description: String, _ props: [String: String], required: [String] = []) -> [String: Any] {
        ["name": name, "description": description,
         "inputSchema": ["type": "object",
                         "properties": props.mapValues { ["type": $0] },
                         "required": required]]
    }
}

/// App ⇄ bridge messages over `agent.sock` (one JSON object per line).
public struct BridgeRequest: Codable, Equatable, Sendable {
    public let id: String
    public let chatID: String
    public let tool: String
    public let input: [String: JSONValue]

    public init(id: String, chatID: String, tool: String, input: [String: JSONValue]) {
        self.id = id
        self.chatID = chatID
        self.tool = tool
        self.input = input
    }
}

public struct BridgeResponse: Codable, Equatable, Sendable {
    public struct Content: Codable, Equatable, Sendable {
        public let type: String          // "text" or "image"
        public let text: String?
        public let data: String?         // base64 for images
        public let mimeType: String?
        public static func text(_ t: String) -> Content { Content(type: "text", text: t, data: nil, mimeType: nil) }
        public static func image(base64: String) -> Content { Content(type: "image", text: nil, data: base64, mimeType: "image/jpeg") }
    }

    public let id: String
    public let ok: Bool
    public let content: [Content]
    public let error: String?

    public init(id: String, ok: Bool, content: [Content], error: String? = nil) {
        self.id = id
        self.ok = ok
        self.content = content
        self.error = error
    }
}

/// Minimal JSON value for tool inputs.
public enum JSONValue: Codable, Equatable, Sendable {
    case string(String), number(Double), bool(Bool), object([String: JSONValue]), array([JSONValue]), null

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let b = try? c.decode(Bool.self) { self = .bool(b) }
        else if let n = try? c.decode(Double.self) { self = .number(n) }
        else if let s = try? c.decode(String.self) { self = .string(s) }
        else if let a = try? c.decode([JSONValue].self) { self = .array(a) }
        else { self = .object(try c.decode([String: JSONValue].self)) }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let s): try c.encode(s)
        case .number(let n): try c.encode(n)
        case .bool(let b): try c.encode(b)
        case .object(let o): try c.encode(o)
        case .array(let a): try c.encode(a)
        case .null: try c.encodeNil()
        }
    }

    public init(any value: Any) {
        switch value {
        case let s as String: self = .string(s)
        case let b as Bool where type(of: value) == type(of: true): self = .bool(b)
        case let n as NSNumber: self = .number(n.doubleValue)
        case let o as [String: Any]: self = .object(o.mapValues(JSONValue.init(any:)))
        case let a as [Any]: self = .array(a.map(JSONValue.init(any:)))
        default: self = .null
        }
    }

    public var any: Any {
        switch self {
        case .string(let s): s
        case .number(let n): n
        case .bool(let b): b
        case .object(let o): o.mapValues(\.any)
        case .array(let a): a.map(\.any)
        case .null: NSNull()
        }
    }

    public var string: String? { if case .string(let s) = self { s } else if case .number(let n) = self { String(n) } else { nil } }
    public var double: Double? { if case .number(let n) = self { n } else if case .string(let s) = self { Double(s) } else { nil } }
}
