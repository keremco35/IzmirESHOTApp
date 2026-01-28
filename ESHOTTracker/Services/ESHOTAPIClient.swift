import Foundation

enum ESHOTAPIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingFailed
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("error_invalid_url", comment: "")
        case .invalidResponse:
            return NSLocalizedString("error_invalid_response", comment: "")
        case .decodingFailed:
            return NSLocalizedString("error_decoding", comment: "")
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

/// API Configuration for İzmir Open Data Portal ESHOT Services
/// Documentation: https://acikveri.izmir.bel.tr
struct ESHOTAPIConfig {
    /// Base URL for İzmir Metropolitan Municipality Open API
    static let baseURL = URL(string: "https://openapi.izmir.bel.tr/api")!
    
    /// IZTEK namespace endpoints for ESHOT services
    static let iztekNamespace = "iztek"
    
    // Available endpoints:
    // - duragayaklasanotobusler/{durakId} - Buses approaching a stop
    // - hattinDuraklari/{hatNo} - Stops on a line
    // - noktayaYakinDuraklar/{lat}/{lon}/{radius} - Stops near a point
    // - hatHareketi/{hatNo} - Line schedule/movement
    
    static let arrivalsPath = "duragayaklasanotobusler"           // GET /{stopId}
    static let stopsOnLinePath = "hattinDuraklari"                // GET /{lineNo}
    static let nearbyStopsPath = "noktayaYakinDuraklar"           // GET /{lat}/{lon}/{radius}
    static let lineSchedulePath = "hatHareketi"                   // GET /{lineNo}
}

final class ESHOTAPIClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    // MARK: - Public API Methods

    /// Fetches buses approaching a specific stop
    /// - Parameter stopId: The stop ID (durak numarası)
    /// - Returns: Array of approaching bus arrivals
    func fetchArrivals(stopId: String) async throws -> [Arrival] {
        let path = "\(ESHOTAPIConfig.iztekNamespace)/\(ESHOTAPIConfig.arrivalsPath)/\(stopId)"
        return try await request(path: path)
    }

    /// Fetches all stops on a specific bus line
    /// - Parameter lineNumber: The bus line number (hat numarası)
    /// - Returns: Array of bus stops on the line
    func fetchStopsOnLine(lineNumber: String) async throws -> [BusStop] {
        let path = "\(ESHOTAPIConfig.iztekNamespace)/\(ESHOTAPIConfig.stopsOnLinePath)/\(lineNumber)"
        return try await request(path: path)
    }

    /// Fetches bus stops near a geographic point
    /// - Parameters:
    ///   - latitude: Latitude coordinate
    ///   - longitude: Longitude coordinate
    ///   - radius: Search radius in meters (default 500m)
    /// - Returns: Array of nearby bus stops
    func fetchNearbyStops(latitude: Double, longitude: Double, radius: Int = 500) async throws -> [BusStop] {
        let latString = String(format: "%.6f", latitude)
        let lonString = String(format: "%.6f", longitude)
        let path = "\(ESHOTAPIConfig.iztekNamespace)/\(ESHOTAPIConfig.nearbyStopsPath)/\(latString)/\(lonString)/\(radius)"
        return try await request(path: path)
    }

    /// Fetches schedule/line information
    /// - Parameter lineNumber: The bus line number
    /// - Returns: Array of bus lines matching the search
    func fetchLineSchedule(lineNumber: String) async throws -> [BusLine] {
        let path = "\(ESHOTAPIConfig.iztekNamespace)/\(ESHOTAPIConfig.lineSchedulePath)/\(lineNumber)"
        return try await request(path: path)
    }

    // MARK: - Static Data (Fallback for unavailable endpoints)

    /// Returns a list of common ESHOT bus lines
    /// This is used when the live API doesn't provide a lines listing endpoint
    func fetchLines() async throws -> [BusLine] {
        // ESHOT does not provide a public "all lines" endpoint
        // Return commonly used lines as fallback
        return commonESHOTLines()
    }

    /// Fetches stops - uses nearby stops API centered on İzmir
    func fetchStops() async throws -> [BusStop] {
        // Center of İzmir - Konak
        return try await fetchNearbyStops(latitude: 38.4237, longitude: 27.1428, radius: 5000)
    }

    /// Fetches vehicles on a specific line
    /// Note: Real-time vehicle location may require a different data source
    func fetchVehicles(lineNumber: String?) async throws -> [BusVehicle] {
        // The current public API doesn't expose real-time vehicle positions directly
        // Return empty array - the app shows arrivals at stops instead
        return []
    }

    // MARK: - Private Methods

    private func request<T: Decodable>(path: String) async throws -> [T] {
        let url = ESHOTAPIConfig.baseURL.appendingPathComponent(path)
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30

        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ESHOTAPIError.invalidResponse
            }
            
            guard 200..<300 ~= httpResponse.statusCode else {
                throw ESHOTAPIError.invalidResponse
            }

            // Try direct array decode
            if let list = try? decoder.decode([T].self, from: data) {
                return list
            }

            // Try wrapped response formats
            if let wrapped = try? decoder.decode(APIResponse<T>.self, from: data) {
                return wrapped.items
            }

            throw ESHOTAPIError.decodingFailed
        } catch let error as ESHOTAPIError {
            throw error
        } catch {
            throw ESHOTAPIError.networkError(error)
        }
    }

    /// Common ESHOT bus lines for quick access
    private func commonESHOTLines() -> [BusLine] {
        [
            BusLine(id: "5", number: "5", description: "Konak - Bornova"),
            BusLine(id: "9", number: "9", description: "Konak - Karşıyaka"),
            BusLine(id: "35", number: "35", description: "Konak - Halkapınar"),
            BusLine(id: "50", number: "50", description: "Fahrettin Altay - Bornova"),
            BusLine(id: "70", number: "70", description: "Konak - Buca"),
            BusLine(id: "85", number: "85", description: "Konak - Üçkuyular"),
            BusLine(id: "99", number: "99", description: "Basmane - Çiğli"),
            BusLine(id: "100", number: "100", description: "Konak - Çeşme"),
            BusLine(id: "120", number: "120", description: "Konak - Aliağa"),
            BusLine(id: "125", number: "125", description: "Üçkuyular - Bornova"),
            BusLine(id: "168", number: "168", description: "Konak - Çeşme Express"),
            BusLine(id: "202", number: "202", description: "Mavişehir - Menemen"),
            BusLine(id: "250", number: "250", description: "İzmir - Selçuk"),
            BusLine(id: "285", number: "285", description: "Karşıyaka - Bornova"),
            BusLine(id: "315", number: "315", description: "Konak - Narlıdere"),
            BusLine(id: "420", number: "420", description: "Konak - Güzelbahçe"),
            BusLine(id: "505", number: "505", description: "Bornova - Çiğli"),
            BusLine(id: "625", number: "625", description: "Konak - Gaziemir"),
            BusLine(id: "750", number: "750", description: "Üçkuyular - Balçova"),
            BusLine(id: "900", number: "900", description: "Konak - Bayraklı"),
        ]
    }
}

/// Wrapper for API responses that contain data in various formats
struct APIResponse<T: Decodable>: Decodable {
    let items: [T]

    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: DynamicCodingKey.self) {
            // Try common wrapper keys
            let wrapperKeys = ["data", "result", "records", "items", "liste", "list", "sonuc"]
            for key in wrapperKeys {
                if let data = try? container.decode([T].self, forKey: DynamicCodingKey(stringValue: key)) {
                    items = data
                    return
                }
            }
        }
        
        // Try single value (direct array)
        let singleValue = try decoder.singleValueContainer()
        items = try singleValue.decode([T].self)
    }
}
