import Foundation
import Supabase

let realtimeProtocolVersion = 1

struct SessionPresence: Codable {
    let sessionType: String
    let sessionId: String
    let userEmail: String
    let startedAt: String
    let simulators: [SimulatorInfo]
    let streamingUdids: [String]
    let presenceVersion: Int

    enum CodingKeys: String, CodingKey {
        case sessionType = "session_type"
        case sessionId = "session_id"
        case userEmail = "user_email"
        case startedAt = "started_at"
        case simulators
        case streamingUdids = "streaming_udids"
        case presenceVersion = "presence_version"
    }
}

struct WebDashboardPresence: Codable {
    let sessionType: String
    let dashboardSessionId: String?

    enum CodingKeys: String, CodingKey {
        case sessionType = "session_type"
        case dashboardSessionId = "dashboard_session_id"
    }
}

struct SimulatorInfo: Codable {
    let udid: String
    let name: String
    let osVersion: String
    let deviceTypeIdentifier: String
    let orderIndex: Int

    enum CodingKeys: String, CodingKey {
        case udid
        case name
        case osVersion = "os_version"
        case deviceTypeIdentifier = "device_type_identifier"
        case orderIndex = "order_index"
    }
}

enum RealtimeCommandKind: String, CaseIterable, Sendable {
    case start
    case stop
    case tap
    case swipe
    case button
    case gesture
    case text
    case push
    case appList = "app_list"
    case screenshot
    case startRecording = "start_recording"
    case stopRecording = "stop_recording"
    case openURL = "open_url"
    case clearLogs = "clear_logs"
}

struct RealtimeCommandEnvelope: Codable, Sendable {
    let protocolVersion: Int
    let commandId: String
    let dashboardSessionId: String
    let kind: String
    let udid: String?
    let payload: JSONObject
    let sentAt: String

    enum CodingKeys: String, CodingKey {
        case protocolVersion = "protocol_version"
        case commandId = "command_id"
        case dashboardSessionId = "dashboard_session_id"
        case kind
        case udid
        case payload
        case sentAt = "sent_at"
    }

    var parsedKind: RealtimeCommandKind? {
        RealtimeCommandKind(rawValue: kind)
    }

    func decodePayload<T: Decodable>(as type: T.Type = T.self) throws -> T {
        try payload.decode(as: T.self)
    }
}

struct RealtimeCommandAck: Codable, Sendable {
    let protocolVersion: Int
    let commandId: String
    let dashboardSessionId: String
    let status: String
    let reason: String?
    let receivedAt: String

    enum CodingKeys: String, CodingKey {
        case protocolVersion = "protocol_version"
        case commandId = "command_id"
        case dashboardSessionId = "dashboard_session_id"
        case status
        case reason
        case receivedAt = "received_at"
    }
}

struct RealtimeCommandResult: Codable, Sendable {
    let protocolVersion: Int
    let commandId: String
    let dashboardSessionId: String
    let kind: String
    let udid: String?
    let status: String
    let reason: String?
    let payload: JSONObject?
    let completedAt: String

    enum CodingKeys: String, CodingKey {
        case protocolVersion = "protocol_version"
        case commandId = "command_id"
        case dashboardSessionId = "dashboard_session_id"
        case kind
        case udid
        case status
        case reason
        case payload
        case completedAt = "completed_at"
    }
}

struct RealtimeLogPayload: Codable, Sendable {
    let protocolVersion: Int
    let udid: String
    let category: String
    let message: String
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case protocolVersion = "protocol_version"
        case udid
        case category
        case message
        case timestamp
    }
}

struct TapCommandPayload: Codable, Sendable {
    let x: Double?
    let y: Double?
    let vw: Double?
    let vh: Double?
    let longPress: Bool?
    let duration: Double?
    let label: String?
}

struct ButtonCommandPayload: Codable, Sendable {
    let button: String
}

struct GestureCommandPayload: Codable, Sendable {
    let gesture: String
}

struct SwipeCommandPayload: Codable, Sendable {
    let startX: Double
    let startY: Double
    let endX: Double
    let endY: Double
    let vw: Double
    let vh: Double
}

struct TextCommandPayload: Codable, Sendable {
    let text: String
}

indirect enum PushCustomPayloadValue: Codable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case object([String: PushCustomPayloadValue])
    case array([PushCustomPayloadValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let object = try? container.decode([String: PushCustomPayloadValue].self) {
            self = .object(object)
        } else if let array = try? container.decode([PushCustomPayloadValue].self) {
            self = .array(array)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported push payload value."
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }

    func foundationValue() -> Any {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return value
        case .double(let value):
            return value
        case .bool(let value):
            return value
        case .object(let value):
            return value.reduce(into: [String: Any]()) { partialResult, item in
                partialResult[item.key] = item.value.foundationValue()
            }
        case .array(let value):
            return value.map { $0.foundationValue() }
        case .null:
            return NSNull()
        }
    }
}

struct PushCommandPayload: Codable, Sendable {
    let bundleId: String
    let title: String?
    let subtitle: String?
    let body: String?
    let badge: Int?
    let sound: String?
    let category: String?
    let contentAvailable: Bool?
    let customPayload: [String: PushCustomPayloadValue]?
}

struct OpenURLCommandPayload: Codable, Sendable {
    let url: String
}

struct AppListResultPayload: Codable, Sendable {
    let apps: [AppListItem]
}

struct AppListItem: Codable, Sendable {
    let bundleId: String
    let name: String
}

struct EmptyResultPayload: Codable, Sendable {}
