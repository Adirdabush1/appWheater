import Foundation
import SwiftData
import Combine

@MainActor
final class WeatherListViewModel: ObservableObject {
    @Published var cities: [City] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let api: WeatherAPIProtocol
    private var modelContext: ModelContext?

    init(api: WeatherAPIProtocol, context: ModelContext?) {
        self.api = api
        self.modelContext = context
        if context != nil { loadSavedCities() }
    }

    convenience init() {
        // Use centralized Config API key provided by the user
        let api = WeatherAPI(apiKey: Config.openWeatherAPIKey)
        self.init(api: api, context: nil)
    }

    func setContext(_ context: ModelContext) {
        guard modelContext == nil else { return }
        self.modelContext = context
        loadSavedCities()
    }

    func loadSavedCities() {
        guard let ctx = modelContext else { return }
        do {
            let fetch = FetchDescriptor<City>()
            let results = try ctx.fetch(fetch)
            self.cities = results

            // If empty, try to seed from configured favorite IDs
            if self.cities.isEmpty {
                let favIDs = Config.favoriteCityIDs
                if !favIDs.isEmpty {
                    Task { await self.importFavoriteIDs(favIDs) }
                }
            }
        } catch {
            print("Failed to fetch cities: \(error)")
            self.cities = []
        }
    }

    func refreshAll() async {
        guard let ctx = modelContext else { return }
        isLoading = true
        errorMessage = nil
        for city in cities {
            do {
                let resp = try await api.fetchCurrentWeather(lat: city.lat, lon: city.lon)
                city.temperature = resp.main.temp
                city.condition = resp.weather.first?.description
                city.icon = resp.weather.first?.icon
                city.lastUpdated = Date()
            } catch {
                errorMessage = "Failed to update \(city.name): \(error)"
            }
        }
        do {
            try ctx.save()
        } catch {
            print("Failed to save context: \(error)")
        }
        isLoading = false
    }

    func addCity(name: String, lat: Double, lon: Double, country: String?) {
        guard let ctx = modelContext else { return }
        let city = City(name: name, country: country, lat: lat, lon: lon)
        ctx.insert(city)
        do {
            try ctx.save()
            loadSavedCities()
        } catch {
            print("Failed to save city: \(error)")
        }
    }

    func delete(at offsets: IndexSet) {
        guard let ctx = modelContext else { return }
        for index in offsets {
            let city = cities[index]
            ctx.delete(city)
        }
        do {
            try ctx.save()
            loadSavedCities()
        } catch {
            print("Failed to delete: \(error)")
        }
    }

    /// Import favorite OpenWeather city IDs, persist them and seed local store with their current weather.
    func importFavoriteIDs(_ ids: [Int]) async {
        guard !ids.isEmpty, let ctx = modelContext else { return }
        isLoading = true
        errorMessage = nil
        // Persist selection so future launches will seed automatically
        Config.persistFavoriteIDs(ids)
        do {
            let responses = try await api.fetchGroup(ids: ids)
            // We'll insert freshly (but avoid duplicate names)
            // Simple dedupe: collect existing names safely
            let existingNames = Set((try? ctx.fetch(FetchDescriptor<City>()).map { $0.name }) ?? [])
            for resp in responses {
                if existingNames.contains(resp.name) { continue }
                let city = City(name: resp.name, country: resp.sys?.country, lat: resp.coord.lat, lon: resp.coord.lon)
                city.temperature = resp.main.temp
                city.condition = resp.weather.first?.description
                city.icon = resp.weather.first?.icon
                city.lastUpdated = Date(timeIntervalSince1970: resp.dt)
                ctx.insert(city)
            }
            do {
                try ctx.save()
            } catch {
                print("Failed to save imported cities: \(error)")
            }
            loadSavedCities()
        } catch {
            print("Failed to import favorite IDs: \(error)")
            errorMessage = "Failed to import favorite cities: \(error)"
        }
        isLoading = false
    }

    func refresh(city: City) async {
        guard let ctx = modelContext else { return }
        isLoading = true
        errorMessage = nil
        do {
            let resp = try await api.fetchCurrentWeather(lat: city.lat, lon: city.lon)
            city.temperature = resp.main.temp
            city.condition = resp.weather.first?.description
            city.icon = resp.weather.first?.icon
            city.lastUpdated = Date()
            try ctx.save()
            let fetch = FetchDescriptor<City>()
            let results = try ctx.fetch(fetch)
            self.cities = results
        } catch {
            errorMessage = "Failed to refresh \(city.name): \(error)"
        }
        isLoading = false
    }

    // MARK: - Geocoding / Search

    func searchCities(query: String, limit: Int) async throws -> [GeocodingResult] {
        try await api.geocode(city: query, limit: limit)
    }

    // MARK: - Seeding defaults and helpers

    /// Seed a handful of well-known cities using coordinates and the current weather endpoint.
    func seedDefaultCities() async {
        guard let ctx = modelContext else { return }
        isLoading = true
        errorMessage = nil
        let seed: [(name: String, country: String?, lat: Double, lon: Double)] = [
            ("London", "GB", 51.5074, -0.1278),
            ("New York", "US", 40.7128, -74.0060),
            ("Tokyo", "JP", 35.6895, 139.6917),
            ("Paris", "FR", 48.8566, 2.3522),
            ("Sydney", "AU", -33.8688, 151.2093)
        ]

        for s in seed {
            do {
                let resp = try await api.fetchCurrentWeather(lat: s.lat, lon: s.lon)
                let city = City(name: s.name, country: s.country, lat: s.lat, lon: s.lon)
                city.temperature = resp.main.temp
                city.condition = resp.weather.first?.description
                city.icon = resp.weather.first?.icon
                city.lastUpdated = Date()
                ctx.insert(city)
            } catch {
                print("Failed to fetch/insert seed city \(s.name): \(error)")
            }
        }

        do {
            try ctx.save()
            loadSavedCities()
        } catch {
            print("Failed to save seeded cities: \(error)")
        }
        isLoading = false
    }

    /// Ensure data is loaded: if no cities exist, try import by favorite IDs, then seed defaults.
    func loadIfNeeded() async {
        guard let ctx = modelContext else { return }
        if let fetched = try? ctx.fetch(FetchDescriptor<City>()), !fetched.isEmpty {
            return
        }

        let favIDs = Config.favoriteCityIDs
        if !favIDs.isEmpty {
            await importFavoriteIDs(favIDs)
        }

        if let recheck = try? ctx.fetch(FetchDescriptor<City>()), recheck.isEmpty {
            await seedDefaultCities()
        }
    }
}
