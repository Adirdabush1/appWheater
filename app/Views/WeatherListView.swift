import SwiftUI
import SwiftData

struct WeatherListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = WeatherListViewModel()
    @StateObject private var network = NetworkMonitor.shared

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

                        Text("Tap + to add a city.")
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
            }
            .onAppear {
                viewModel.setContext(modelContext)
                Task { await viewModel.loadIfNeeded() }
            }
            .alert("Error", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }
}
