import SwiftUI
import SwiftData

struct WeatherDetailView: View {
    @Bindable var city: City
    @ObservedObject var viewModel: WeatherListViewModel

    @State private var isRefreshing = false
    @StateObject private var network = NetworkMonitor.shared

    var body: some View {
        VStack(spacing: 12) {
            if !network.isConnected {
                Text("Offline — showing last saved data")
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.yellow.opacity(0.2))
            }

            Text(city.name)
                .font(.largeTitle)
                .bold()

            if let temp = city.temperature {
                Text(String(format: "%.0f°", temp))
                    .font(.system(size: 48))
            } else {
                ProgressView()
            }

            if let condition = city.condition {
                HStack(spacing: 12) {
                    if let icon = city.icon, let url = URL(string: "https://openweathermap.org/img/wn/\(icon)@2x.png") {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView().frame(width: 56, height: 56)
                            case .success(let image):
                                image.resizable().scaledToFit().frame(width: 56, height: 56)
                            case .failure:
                                Image(systemName: "cloud").resizable().scaledToFit().frame(width: 56, height: 56)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    Text(condition.capitalized).font(.title3)
                }
            }

            HStack(spacing: 24) {
                VStack { Text("Max").font(.caption); Text(city.temperatureMax != nil ? String(format: "%.0f°", city.temperatureMax!) : "—") }
                VStack { Text("Min").font(.caption); Text(city.temperatureMin != nil ? String(format: "%.0f°", city.temperatureMin!) : "—") }
                VStack { Text("Humidity").font(.caption); Text(city.humidity != nil ? "\(city.humidity!)%" : "—") }
                VStack { Text("Wind").font(.caption); Text(city.windSpeed != nil ? String(format: "%.1f m/s", city.windSpeed!) : "—") }
            }
            .font(.headline)

            if let updated = city.lastUpdated {
                Text("Last updated: \(updated, style: .time)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                Task {
                    // Set visible refreshing state on main actor
                    await MainActor.run { isRefreshing = true }

                    // Start a minimum visible delay in parallel (1.5s)
                    async let minimumDelay: Void = Task.sleep(nanoseconds: 1_500_000_000)

                    // Call the view model refresh on the MainActor to avoid passing the City across concurrency
                    await MainActor.run {
                        // call is async but we're already awaiting it here
                        Task {
                            await viewModel.refresh(city: city)
                        }
                    }

                    // Wait for the minimum delay to finish
                    _ = await (try? await minimumDelay)

                    await MainActor.run { isRefreshing = false }
                }
            }) {
                HStack(spacing: 10) {
                    if isRefreshing {
                        ProgressView().frame(width: 18, height: 18)
                    }
                    Image(systemName: "arrow.clockwise").imageScale(.medium).foregroundColor(.white)
                    Text("Refresh").foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRefreshing)
            .tint(.accentColor)
            .padding(.bottom)
        }
        .padding()
        .navigationTitle(city.name)
        // Show an alert if the view model reports an error
        .alert("Error", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }
}
