import SwiftUI
import SwiftData

struct WeatherDetailView: View {
    @Bindable var city: City
    @ObservedObject var viewModel: WeatherListViewModel
    @State private var isRefreshing = false
    @State private var animateIcon = false

    var body: some View {
        VStack(spacing: 12) {
            Text(city.name).font(.largeTitle).bold()

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
                                ProgressView()
                                    .frame(width: 56, height: 56)
                            case .success(let img):
                                img.resizable()
                                    .scaledToFit()
                                    .frame(width: 56, height: 56)
                                    .rotationEffect(animateIcon ? Angle.degrees(360) : Angle.degrees(0))
                                    .scaleEffect(animateIcon ? 1.05 : 1.0)
                                    .animation(.linear(duration: 1.2), value: animateIcon)
                            case .failure:
                                Image(systemName: "cloud")
                                    .resizable().scaledToFit().frame(width: 56, height: 56)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    Text(condition.capitalized)
                        .font(.title3)
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
                    // Start visible refresh state and ensure it lasts at least 3 seconds
                    await MainActor.run {
                        isRefreshing = true
                        animateIcon = true
                    }

                    async let networkRefresh: Void = viewModel.refresh(city: city)
                    async let minimumDelay: Void = Task.sleep(nanoseconds: 3_000_000_000)

                    // Wait for both the network call and the minimum delay
                    _ = await (try? await networkRefresh, try? await minimumDelay)

                    await MainActor.run {
                        animateIcon = false
                        isRefreshing = false
                    }
                }
            }) {
                HStack(spacing: 10) {
                    if isRefreshing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(width: 18, height: 18)
                    }
                    Image(systemName: "arrow.clockwise")
                        .imageScale(.medium)
                        .foregroundColor(.white)
                    Text("Refresh")
                        .foregroundColor(.white)
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
    }
}
