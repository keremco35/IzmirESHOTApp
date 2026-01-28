import MapKit
import SwiftUI

struct MapScreen: View {
    @StateObject private var viewModel = BusTrackingViewModel()
    @State private var showingSearch = true

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Full screen map
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
                .ignoresSafeArea(edges: .bottom)

                // Bottom sheet overlay
                VStack(spacing: 0) {
                    // Handle bar
                    Capsule()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 40, height: 5)
                        .padding(.top, 8)
                        .onTapGesture {
                            withAnimation { showingSearch.toggle() }
                        }

                    if showingSearch {
                        // Search controls
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
                        .padding(.horizontal)
                        .padding(.top, 12)

                        // Status messages
                        if viewModel.isOffline {
                            HStack {
                                Image(systemName: "wifi.slash")
                                Text("offline_cache")
                            }
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal)
                        }

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }

                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.top, 8)
                        }

                        // Results list
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                // Stops or arrivals
                                if !viewModel.stopResults.isEmpty {
                                    ForEach(viewModel.stopResults) { stop in
                                        StopRow(stop: stop, isSelected: viewModel.selectedStop?.id == stop.id) {
                                            Task { await viewModel.selectStop(stop) }
                                        }
                                    }
                                }

                                // Arrivals for selected stop
                                if let stop = viewModel.selectedStop, !viewModel.arrivals.isEmpty {
                                    Text(String(format: NSLocalizedString("arrivals_for_stop", comment: ""), stop.name))
                                        .font(.headline)
                                        .padding(.top, 12)

                                    ForEach(viewModel.arrivals) { arrival in
                                        ArrivalRow(arrival: arrival)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                        .frame(maxHeight: 250)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(radius: 8)
                )
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .navigationTitle(Text("app_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation { showingSearch.toggle() }
                    } label: {
                        Image(systemName: showingSearch ? "chevron.down" : "magnifyingglass")
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .task { await viewModel.start() }
        .onDisappear { viewModel.stop() }
    }
}

private struct MapAnnotationView: View {
    let item: MapAnnotationItem

    var body: some View {
        VStack(spacing: 2) {
            if item.kind == .bus {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 32, height: 32)
                    Text(item.title)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            } else {
                Image(systemName: "mappin.circle.fill")
                    .font(.title)
                    .foregroundColor(.red)
            }
        }
    }
}

private struct StopRow: View {
    let stop: BusStop
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(stop.name)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .bold : .regular)
                    if !stop.lines.isEmpty {
                        Text(stop.lines.prefix(5).joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color(UIColor.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ArrivalRow: View {
    let arrival: Arrival

    var body: some View {
        HStack {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(arrival.lineNumber)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(arrival.direction)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(arrival.estimatedArrivalText)
                .font(.headline)
                .foregroundColor(.accentColor)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}
