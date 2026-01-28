import MapKit
import SwiftUI

struct MapScreen: View {
    @StateObject private var viewModel = BusTrackingViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Map(
                    coordinateRegion: $viewModel.region,
                    interactionModes: .all,
                    showsUserLocation: true,
                    annotationItems: viewModel.mapAnnotations
                ) { item in
                    MapAnnotation(coordinate: item.coordinate) {
                        MapAnnotationView(item: item)
                    }
                }
                .frame(height: 320)

                VStack(spacing: 12) {
                    Picker("search_mode", selection: $viewModel.searchMode) {
                        Text("search_line").tag(SearchMode.line)
                        Text("search_stop").tag(SearchMode.stop)
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        TextField("search_placeholder", text: $viewModel.searchText)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .textFieldStyle(.roundedBorder)

                        Button("search_action") {
                            Task { await viewModel.performSearch() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()

                List {
                    if viewModel.isOffline {
                        Text("offline_cache")
                            .foregroundColor(.orange)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }

                    if viewModel.isLoading {
                        ProgressView()
                    }

                    if viewModel.searchMode == .line {
                        Section(header: Text("lines_title")) {
                            ForEach(viewModel.lineResults) { line in
                                Button {
                                    Task { await viewModel.selectLine(line) }
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(line.displayName)
                                            .font(.headline)
                                        if !line.description.isEmpty {
                                            Text(line.description)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        Section(header: Text("stops_title")) {
                            ForEach(viewModel.stopResults) { stop in
                                Button {
                                    Task { await viewModel.selectStop(stop) }
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(stop.name)
                                            .font(.headline)
                                        Text(stop.lines.joined(separator: ", "))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    if let stop = viewModel.selectedStop {
                        Section(header: Text(String(format: NSLocalizedString("arrivals_for_stop", comment: ""), stop.name))) {
                            if viewModel.arrivals.isEmpty {
                                Text("no_arrivals")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(viewModel.arrivals) { arrival in
                                    ArrivalRow(arrival: arrival)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle(Text("app_title"))
        }
        .task { await viewModel.start() }
        .onDisappear { viewModel.stop() }
    }
}

private struct MapAnnotationView: View {
    let item: MapAnnotationItem

    var body: some View {
        VStack(spacing: 4) {
            if item.kind == .bus {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 36, height: 36)
                    Text(item.title)
                        .font(.caption2)
                        .foregroundColor(.white)
                }
            } else {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
            }
            Text(item.subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

private struct ArrivalRow: View {
    let arrival: Arrival

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(arrival.lineNumber)
                    .font(.headline)
                Text(arrival.direction)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(arrival.estimatedArrivalText)
                .font(.headline)
        }
    }
}
