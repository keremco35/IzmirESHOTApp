import Foundation

struct BusLine: Identifiable, Codable, Hashable {
    let id: String
    let number: String
    let description: String

    var displayName: String {
        number.isEmpty ? description : number
    }

    init(id: String, number: String, description: String) {
        self.id = id
        self.number = number
        self.description = description
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        let id = container.decodeString(forKeys: ["HatId", "hatId", "Id", "id"]) ?? UUID().uuidString
        let number = container.decodeString(forKeys: ["HatNo", "hatNo", "LineNo", "lineNo", "No", "no"]) ?? ""
        let description = container.decodeString(forKeys: ["HatAdi", "hatAdi", "LineName", "lineName", "Ad", "ad"]) ?? ""
        self.id = id
        self.number = number
        self.description = description
    }
}
