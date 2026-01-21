import SwiftUI
import SwiftData

struct WeatherListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = WeatherListViewModel()
    @StateObject private var network = NetworkMonitor.shared

    @State private var showingImportSheet = false
    @State private var importText: String = ""
    @State private var reseedCompleted: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !network.isConnected {
                    Text("Offline — showing last saved data")
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color.yellow.opacity(0.2))
                }

                if viewModel.cities.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "cloud.sun.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.accentColor)

                        Text("No cities yet")
                            .font(.title2)
                            .bold()

                        Text("Tap + to add a city, or import your favorite city IDs from OpenWeather.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        Spacer()
                    }
                } else {
                    List {
                        ForEach(viewModel.cities, id: \.id) { city in
                            NavigationLink(destination: WeatherDetailView(city: city, viewModel: viewModel)) {
                                WeatherRowView(city: city)
                            }
                        }
                        .onDelete(perform: viewModel.delete)
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await viewModel.refreshAll() }
                }

                if viewModel.isLoading {
                    ProgressView("Loading…")
                        .padding(.vertical, 8)
                }
            }
            .navigationTitle("Weather")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingImportSheet = true }) {
                        Image(systemName: "square.and.arrow.down.on.square")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await viewModel.refreshAll() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AddCityView(viewModel: viewModel)) {
                        Image(systemName: "plus")
                    }
                    .disabled(viewModel.isLoading)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.resetAndReseed()
                            reseedCompleted = true
                        }
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .sheet(isPresented: $showingImportSheet) {
                NavigationStack {
                    Form {
                        Section(header: Text("Paste city IDs")) {
                            TextEditor(text: $importText)
                                .frame(minHeight: 120)
                                .disableAutocorrection(true)
                                .autocapitalization(.none)
                            Text("Enter comma-separated OpenWeather city IDs, e.g. 2643743,5128581")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .navigationTitle("Import City IDs")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Import") {
                                let ids = importText.split(separator: ",")
                                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                    .compactMap { Int($0) }
                                Task {
                                    await viewModel.importFavoriteIDs(ids)
                                    showingImportSheet = false
                                    importText = ""
                                }
                            }
                            .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingImportSheet = false }
                        }
                    }
                }
            }
            .onAppear {
                viewModel.setContext(modelContext)
                Task { await viewModel.loadIfNeeded() }
            }
        }
    }
}
