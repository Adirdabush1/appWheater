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
                city.temperatureMin = resp.main.temp_min
                city.temperatureMax = resp.main.temp_max
                city.humidity = resp.main.humidity
                city.windSpeed = resp.wind?.speed
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

    // MARK: - Networking helpers

    /// Import favorite OpenWeather city IDs, persist them and seed local store with their current weather.
    func importFavoriteIDs(_ ids: [Int]) async {
        guard !ids.isEmpty, let ctx = modelContext else { return }
        isLoading = true
        errorMessage = nil
        Config.persistFavoriteIDs(ids)
        do {
            let responses = try await api.fetchGroup(ids: ids)
            let existingNames = Set((try? ctx.fetch(FetchDescriptor<City>()).map { $0.name }) ?? [])
            for resp in responses {
                if existingNames.contains(resp.name) { continue }
                let city = City(name: resp.name, country: resp.sys?.country, lat: resp.coord.lat, lon: resp.coord.lon)
                city.temperature = resp.main.temp
                city.temperatureMin = resp.main.temp_min
                city.temperatureMax = resp.main.temp_max
                city.humidity = resp.main.humidity
                city.windSpeed = resp.wind?.speed
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
            city.temperatureMin = resp.main.temp_min
            city.temperatureMax = resp.main.temp_max
            city.humidity = resp.main.humidity
            city.windSpeed = resp.wind?.speed
            city.condition = resp.weather.first?.description
            city.icon = resp.weather.first?.icon
            city.lastUpdated = Date()
            try ctx.save()
            loadSavedCities()
        } catch {
            errorMessage = "Failed to refresh \(city.name): \(error)"
        }
        isLoading = false
    }

    // MARK: - Geocoding / Search

    func searchCities(query: String, limit: Int) async throws -> [GeocodingResult] {
        try await api.geocode(city: query, limit: limit)
    }

    // MARK: - Seeding defaults

    func seedDefaultCities() async {
        guard let ctx = modelContext else { return }
        isLoading = true
        errorMessage = nil
        let seed: [(name: String, country: String?, lat: Double, lon: Double)] = [
            ("London", "GB", 51.5074, -0.1278),
            ("New York", "US", 40.7128, -74.0060),
            ("Tokyo", "JP", 35.6895, 139.6917),
            ("Paris", "FR", 48.8566, 2.3522),
            ("Sydney", "AU", -33.8688, 151.2093),
            ("Moscow", "RU", 55.7558, 37.6173),
            ("Beijing", "CN", 39.9042, 116.4074),
            ("Mumbai", "IN", 19.0760, 72.8777),
            ("São Paulo", "BR", -23.5505, -46.6333),
            ("Mexico City", "MX", 19.4326, -99.1332),
            ("Cairo", "EG", 30.0444, 31.2357),
            ("Lagos", "NG", 6.5244, 3.3792),
            ("Istanbul", "TR", 41.0082, 28.9784),
            ("Jakarta", "ID", -6.2088, 106.8456),
            ("Seoul", "KR", 37.5665, 126.9780),
            ("Los Angeles", "US", 34.0522, -118.2437),
            ("Chicago", "US", 41.8781, -87.6298),
            ("Toronto", "CA", 43.6532, -79.3832),
            ("Madrid", "ES", 40.4168, -3.7038),
            ("Berlin", "DE", 52.5200, 13.4050),
            ("Bangkok", "TH", 13.7563, 100.5018),
            ("Buenos Aires", "AR", -34.6037, -58.3816),
            ("Lima", "PE", -12.0464, -77.0428),
            ("Johannesburg", "ZA", -26.2041, 28.0473),
            ("Nairobi", "KE", -1.2921, 36.8219),
            ("Riyadh", "SA", 24.7136, 46.6753),
            ("Tehran", "IR", 35.6892, 51.3890),
            ("Dubai", "AE", 25.2048, 55.2708),
            ("Kuala Lumpur", "MY", 3.1390, 101.6869),
            ("Singapore", "SG", 1.3521, 103.8198)
        ]

        for s in seed {
            do {
                let resp = try await api.fetchCurrentWeather(lat: s.lat, lon: s.lon)
                let city = City(name: s.name, country: s.country, lat: s.lat, lon: s.lon)
                city.temperature = resp.main.temp
                city.temperatureMin = resp.main.temp_min
                city.temperatureMax = resp.main.temp_max
                city.humidity = resp.main.humidity
                city.windSpeed = resp.wind?.speed
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
