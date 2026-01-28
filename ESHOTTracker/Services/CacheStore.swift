import Foundation

final class CacheStore {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    enum CacheKey: Hashable {
        case vehicles
        case lines
        case stops
        case stopsOnLine(String)
        case arrivals(String)

        var fileName: String {
            switch self {
            case .vehicles:
                return "vehicles.json"
            case .lines:
                return "lines.json"
            case .stops:
                return "stops.json"
            case .stopsOnLine(let lineNumber):
                return "stops-line-\(lineNumber).json"
            case .arrivals(let stopId):
                return "arrivals-\(stopId).json"
            }
        }
    }

    func save<T: Encodable>(_ value: T, for key: CacheKey) {
        do {
            let data = try encoder.encode(value)
            try data.write(to: url(for: key), options: .atomic)
        } catch {
            return
        }
    }

    func load<T: Decodable>(_ key: CacheKey) -> T? {
        do {
            let data = try Data(contentsOf: url(for: key))
            return try decoder.decode(T.self, from: data)
        } catch {
            return nil
        }
    }

    private func url(for key: CacheKey) -> URL {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent("eshot-cache-\(key.fileName)")
    }
}
