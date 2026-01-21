import SwiftUI

struct AddCityView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var viewModel: WeatherListViewModel
    @State private var query: String = ""
    @State private var results: [GeocodingResult] = []
    @State private var isSearching: Bool = false
    
    var body: some View {
        VStack {
            TextField("Search city", text: $query, onCommit: {
                Task { await search() }
            })
            .textFieldStyle(.roundedBorder)
            .padding()

            if isSearching {
                ProgressView()
            } else if results.isEmpty {
                Spacer()
                Text("No results")
                Spacer()
            } else {
                List(results, id: \.name) { res in
                    Button(action: {
                        viewModel.addCity(name: res.name, lat: res.lat, lon: res.lon, country: res.country)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        VStack(alignment: .leading) {
                            Text(res.name)
                            Text(res.country).font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Add City")
        .padding(.top)
    }

    func search() async {
        guard !query.isEmpty else { return }
        isSearching = true
        let vm = viewModel
        do {
            results = try await vm.searchCities(query: query, limit: 5)
        } catch {
            print("Search failed: \(error)")
            results = []
        }
        isSearching = false
    }
}
