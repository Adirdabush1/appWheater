import SwiftUI
import SwiftData

struct WeatherRowView: View {
    @ObservedObject var city: City

    var body: some View {
        HStack(spacing: 12) {
            // Weather icon
            Group {
                if let icon = city.icon, let url = URL(string: "https://openweathermap.org/img/wn/\(icon)@2x.png") {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 44, height: 44)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                        case .failure:
                            Image(systemName: "cloud.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                                .foregroundColor(.secondary)
                        @unknown default:
                            Image(systemName: "questionmark")
                                .frame(width: 44, height: 44)
                        }
                    }
                } else {
                    Image(systemName: "cloud.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(city.name)
                        .font(.headline)
                    if let country = city.country {
                        Text(country)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let updated = city.lastUpdated {
                    Text("Updated \(updated, style: .time)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("No recent data")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let temp = city.temperature {
                    Text(String(format: "%.0f°", temp))
                        .font(.title2)
                        .bold()
                } else {
                    ProgressView()
                        .frame(width: 24, height: 24)
                }

                if let condition = city.condition {
                    Text(condition.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts: [String] = []
        parts.append(city.name)
        if let country = city.country { parts.append(country) }
        if let temp = city.temperature { parts.append(String(format: "%.0f degrees", temp)) }
        if let condition = city.condition { parts.append(condition) }
        return parts.joined(separator: ", ")
    }
}
