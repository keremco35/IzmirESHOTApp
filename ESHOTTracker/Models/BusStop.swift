import CoreLocation
import Foundation

struct BusStop: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let lines: [String]

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(id: String, name: String, latitude: Double, longitude: Double, lines: [String]) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.lines = lines
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        let id = container.decodeString(forKeys: ["DurakId", "durakId", "DurakNo", "durakNo", "Id", "id"]) ?? UUID().uuidString
        let name = container.decodeString(forKeys: ["DurakAdi", "durakAdi", "Ad", "ad", "StopName", "stopName"]) ?? "-"
        let lat = container.decodeDouble(forKeys: ["Enlem", "enlem", "Lat", "lat", "Latitude", "latitude"]) ?? 0
        let lon = container.decodeDouble(forKeys: ["Boylam", "boylam", "Lon", "lon", "Longitude", "longitude"]) ?? 0
        let linesString = container.decodeString(forKeys: ["Hatlar", "hatlar", "Lines", "lines"]) ?? ""
        let lines = linesString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        self.id = id
        self.name = name
        self.latitude = lat
        self.longitude = lon
        self.lines = lines
    }
}
