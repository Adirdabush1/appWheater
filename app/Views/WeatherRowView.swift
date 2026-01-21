import SwiftUI
import SwiftData

struct WeatherRowView: View {
    @Bindable var city: City

    private func iconURL(for code: String?) -> URL? {
        guard let code = code else { return nil }
        return URL(string: "https://openweathermap.org/img/wn/\(code)@2x.png")
    }

    var body: some View {
        HStack {
            // Weather icon
            if let url = iconURL(for: city.icon) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 44, height: 44)
                    case .success(let img):
                        img.resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                    case .failure:
                        Image(systemName: "cloud")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "cloud")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
            }

            VStack(alignment: .leading) {
                Text(city.name)
                    .font(.headline)
                if let country = city.country {
                    Text(country)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if let temp = city.temperature {
                Text(String(format: "%.0f°", temp))
                    .font(.title2)
            } else {
                ProgressView()
            }
        }
        .padding(.vertical, 8)
    }
}
