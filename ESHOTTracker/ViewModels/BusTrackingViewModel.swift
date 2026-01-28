import Foundation
import MapKit

enum SearchMode: String, CaseIterable {
    case line
    case stop
}

enum MapAnnotationKind {
    case bus
    case stop
}

struct MapAnnotationItem: Identifiable, Hashable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let title: String
    let subtitle: String
    let kind: MapAnnotationKind
}

@MainActor
final class BusTrackingViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.4237, longitude: 27.1428),
        span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
    )
    @Published var mapAnnotations: [MapAnnotationItem] = []
    @Published var vehicles: [BusVehicle] = []
    @Published var lineResults: [BusLine] = []
    @Published var stopResults: [BusStop] = []
    @Published var arrivals: [Arrival] = []
    @Published var isLoading = false
    @Published var isOffline = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var searchMode: SearchMode = .line
    @Published var selectedLine: BusLine?
    @Published var selectedStop: BusStop?

    private let apiClient = ESHOTAPIClient()
    private let cache = CacheStore()
    private let networkMonitor = NetworkMonitor()
    private var refreshTask: Task<Void, Never>?

    func start() async {
        networkMonitor.start()
        await loadCachedState()
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
        networkMonitor.stop()
    }

    /// Performs search based on current mode and search text
    func performSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            errorMessage = NSLocalizedString("error_empty_search", comment: "")
            return
        }
        
        errorMessage = nil
        
        switch searchMode {
        case .line:
            await searchLine(query)
        case .stop:
            await searchStops(query)
        }
    }

    /// Direct line search - user enters any line number
    private func searchLine(_ lineNumber: String) async {
        isLoading = true
        defer { isLoading = false }
        
        // Create a line object from user input
        let line = BusLine(id: lineNumber, number: lineNumber, description: "Hat \(lineNumber)")
        lineResults = [line]
        
        // Automatically select and load stops for this line
        await selectLine(line)
    }

    func selectLine(_ line: BusLine) async {
        selectedLine = line
        selectedStop = nil
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch stops on this line
            let stops = try await apiClient.fetchStopsOnLine(lineNumber: line.number)
            stopResults = stops
            cache.save(stops, for: .stopsOnLine(line.number))
            
            // Show stops on map
            updateAnnotationsForStops(stops)
            
            // If we have stops, fit the map to show all
            if let firstStop = stops.first {
                updateRegion(for: firstStop.coordinate, span: 0.1)
            }
            
            isOffline = false
            errorMessage = nil
        } catch {
            isOffline = true
            // Try loading from cache
            if let cached: [BusStop] = cache.load(.stopsOnLine(line.number)) {
                stopResults = cached
                updateAnnotationsForStops(cached)
            } else {
                errorMessage = NSLocalizedString("error_line_stops", comment: "")
            }
        }
    }

    func selectStop(_ stop: BusStop) async {
        selectedStop = stop
        isLoading = true
        defer { isLoading = false }
        
        await refreshArrivals(for: stop)
        updateAnnotationsWithSelectedStop(stop)
        updateRegion(for: stop.coordinate, span: 0.02)
    }

    /// Search stops by name or nearby
    private func searchStops(_ query: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try fetching nearby stops to İzmir center
            let stops = try await apiClient.fetchNearbyStops(
                latitude: 38.4237,
                longitude: 27.1428,
                radius: 5000
            )
            
            // Filter by query
            let filtered = stops.filter { stop in
                stop.name.localizedCaseInsensitiveContains(query) ||
                stop.lines.contains { $0.localizedCaseInsensitiveContains(query) }
            }
            
            stopResults = filtered.isEmpty ? stops : filtered
            cache.save(stopResults, for: .stops)
            updateAnnotationsForStops(stopResults)
            isOffline = false
        } catch {
            isOffline = true
            if let cached: [BusStop] = cache.load(.stops) {
                let filtered = cached.filter { stop in
                    stop.name.localizedCaseInsensitiveContains(query)
                }
                stopResults = filtered.isEmpty ? cached : filtered
                updateAnnotationsForStops(stopResults)
            }
            errorMessage = NSLocalizedString("error_stops", comment: "")
        }
    }

    private func refreshArrivals(for stop: BusStop) async {
        do {
            let arrivals = try await apiClient.fetchArrivals(stopId: stop.id)
            self.arrivals = arrivals
            cache.save(arrivals, for: .arrivals(stop.id))
            isOffline = false
            errorMessage = nil
        } catch {
            isOffline = true
            if let cached: [Arrival] = cache.load(.arrivals(stop.id)) {
                self.arrivals = cached
            }
            errorMessage = NSLocalizedString("error_arrivals", comment: "")
        }
    }

    private func loadCachedState() async {
        // Load previously viewed line stops if available
        if let lastLine = selectedLine,
           let cachedStops: [BusStop] = cache.load(.stopsOnLine(lastLine.number)) {
            stopResults = cachedStops
            updateAnnotationsForStops(cachedStops)
        }
    }

    // MARK: - Map Annotations

    private func updateAnnotationsForStops(_ stops: [BusStop]) {
        mapAnnotations = stops.map { stop in
            MapAnnotationItem(
                id: stop.id,
                coordinate: stop.coordinate,
                title: stop.name,
                subtitle: stop.lines.prefix(3).joined(separator: ", "),
                kind: .stop
            )
        }
    }

    private func updateAnnotationsWithSelectedStop(_ stop: BusStop) {
        // Keep existing stop annotations but highlight selected
        var annotations = stopResults.map { s in
            MapAnnotationItem(
                id: s.id,
                coordinate: s.coordinate,
                title: s.name,
                subtitle: s.lines.prefix(3).joined(separator: ", "),
                kind: .stop
            )
        }
        
        // Ensure selected stop is included
        if !annotations.contains(where: { $0.id == stop.id }) {
            annotations.append(MapAnnotationItem(
                id: stop.id,
                coordinate: stop.coordinate,
                title: stop.name,
                subtitle: stop.lines.joined(separator: ", "),
                kind: .stop
            ))
        }
        
        mapAnnotations = annotations
    }

    private func updateRegion(for coordinate: CLLocationCoordinate2D, span: Double = 0.05) {
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        )
    }
}

protocol BusLineProtocol {
    var number: String { get }
    var description: String { get }
}

extension BusLine: BusLineProtocol {}
