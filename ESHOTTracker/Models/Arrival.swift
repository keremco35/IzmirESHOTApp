import Foundation

struct Arrival: Identifiable, Codable, Hashable {
    let id: String
    let lineNumber: String
    let direction: String
    let estimatedArrivalMinutes: Int?

    var estimatedArrivalText: String {
        if let minutes = estimatedArrivalMinutes {
            return String(format: NSLocalizedString("arrival_minutes", comment: ""), minutes)
        }
        return NSLocalizedString("arrival_unknown", comment: "")
    }

    init(id: String, lineNumber: String, direction: String, estimatedArrivalMinutes: Int?) {
        self.id = id
        self.lineNumber = lineNumber
        self.direction = direction
        self.estimatedArrivalMinutes = estimatedArrivalMinutes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        let id = container.decodeString(forKeys: ["Id", "id", "SeferId", "seferId"]) ?? UUID().uuidString
        let line = container.decodeString(forKeys: ["HatNo", "hatNo", "Line", "line"]) ?? "-"
        let direction = container.decodeString(forKeys: ["Yon", "yon", "Direction", "direction"]) ?? "-"
        let minutesString = container.decodeString(forKeys: ["TahminiVarisDakika", "tahminiVarisDakika", "EstimatedMinutes", "estimatedMinutes"])
        let minutes = minutesString.flatMap { Int($0) }
        self.id = id
        self.lineNumber = line
        self.direction = direction
        self.estimatedArrivalMinutes = minutes
    }
}
