import SwiftUI
import SwiftData

struct WeatherDetailView: View {
    @ObservedObject var city: City
    @ObservedObject var viewModel: WeatherListViewModel

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

            if let updated = city.lastUpdated {
                Text("Last updated: \(updated, style: .time)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                Task { await viewModel.refresh(city: city) }
            }) {
                HStack {
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
