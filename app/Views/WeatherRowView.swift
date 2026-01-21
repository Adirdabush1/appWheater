import SwiftUI
import SwiftData

struct WeatherRowView: View {
    @Bindable var city: City

    var body: some View {
        HStack {
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
