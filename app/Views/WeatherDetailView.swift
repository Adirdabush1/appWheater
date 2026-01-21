import SwiftUI
import SwiftData

struct WeatherDetailView: View {
    @Bindable var city: City
    @ObservedObject var viewModel: WeatherListViewModel
    @State private var isRefreshing = false

    var body: some View {
        VStack(spacing: 12) {
            Text(city.name).font(.largeTitle).bold()
            if let temp = city.temperature {
                Text(String(format: "%.0f°", temp)).font(.system(size: 48))
            } else {
                ProgressView()
            }

            if let condition = city.condition {
                Text(condition.capitalized)
            }

            HStack(spacing: 20) {
                if let tmax = city.temperatureMax {
                    VStack { Text("Max").font(.caption); Text(String(format: "%.0f°", tmax)) }
                }
                if let tmin = city.temperatureMin {
                    VStack { Text("Min").font(.caption); Text(String(format: "%.0f°", tmin)) }
                }
                if let hum = city.humidity {
                    VStack { Text("Humidity").font(.caption); Text("\(hum)%") }
                }
                if let wind = city.windSpeed {
                    VStack { Text("Wind").font(.caption); Text(String(format: "%.1f m/s", wind)) }
                }
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
                    isRefreshing = true
                    await viewModel.refresh(city: city)
                    isRefreshing = false
                }
            }) {
                HStack {
                    if isRefreshing { ProgressView().progressViewStyle(CircularProgressViewStyle()) }
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
        }
        .padding()
        .navigationTitle(city.name)
    }
}
