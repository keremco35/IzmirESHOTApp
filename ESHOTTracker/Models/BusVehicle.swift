import CoreLocation
import Foundation

struct BusVehicle: Identifiable, Codable, Hashable {
    let id: String
    let lineNumber: String
    let direction: String
    let latitude: Double
    let longitude: Double
    let updatedAt: Date?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(id: String, lineNumber: String, direction: String, latitude: Double, longitude: Double, updatedAt: Date?) {
        self.id = id
        self.lineNumber = lineNumber
        self.direction = direction
        self.latitude = latitude
        self.longitude = longitude
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        let id = container.decodeString(forKeys: ["AracNo", "aracNo", "VehicleId", "vehicleId", "Id", "id"]) ?? UUID().uuidString
        let line = container.decodeString(forKeys: ["HatNo", "hatNo", "Line", "line", "Route", "route"]) ?? "-"
        let direction = container.decodeString(forKeys: ["Yon", "yon", "Direction", "direction"]) ?? "-"
        let lat = container.decodeDouble(forKeys: ["Enlem", "enlem", "Lat", "lat", "Latitude", "latitude"]) ?? 0
        let lon = container.decodeDouble(forKeys: ["Boylam", "boylam", "Lon", "lon", "Longitude", "longitude"]) ?? 0
        let updated = container.decodeString(forKeys: ["GuncellemeZamani", "guncellemeZamani", "UpdatedAt", "updatedAt"])
        self.id = id
        self.lineNumber = line
        self.direction = direction
        self.latitude = lat
        self.longitude = lon
        self.updatedAt = ISO8601DateFormatter().date(from: updated ?? "")
    }
}
