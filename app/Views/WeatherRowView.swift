import SwiftUI
import SwiftData

struct WeatherRowView: View {
    @Bindable var city: City

    var body: some View {
        HStack {
            if let icon = city.icon, let url = URL(string: "https://openweathermap.org/img/wn/\(icon)@2x.png") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 44, height: 44)
                    case .success(let image):
                        image.resizable().scaledToFit().frame(width: 44, height: 44)
                    case .failure:
                        Image(systemName: "cloud")
                            .resizable().scaledToFit().frame(width: 44, height: 44)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "cloud.sun.fill")
                    .resizable().scaledToFit().frame(width: 44, height: 44)
                    .foregroundColor(.accentColor)
            }

            VStack(alignment: .leading) {
                Text(city.name)
                    .font(.headline)
                if let country = city.country {
                    Text(country)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 12) {
                    Text(city.temperature != nil ? String(format: "%.0f°", city.temperature!) : "—")
                        .font(.title2)
                    Text(city.temperatureMax != nil ? "H: \(String(format: "%.0f°", city.temperatureMax!))" : "H: —")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(city.temperatureMin != nil ? "L: \(String(format: "%.0f°", city.temperatureMin!))" : "L: —")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let wind = city.windSpeed {
                        Text(String(format: "· %.1f m/s", wind))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
