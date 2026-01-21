import Foundation

enum WeatherAPIError: Error {
    case badURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(statusCode: Int)
}

protocol WeatherAPIProtocol {
    func fetchCurrentWeather(lat: Double, lon: Double) async throws -> CurrentWeatherResponse
    func geocode(city: String, limit: Int) async throws -> [GeocodingResult]
    func fetchGroup(ids: [Int]) async throws -> [CurrentWeatherResponse]
}

final class WeatherAPI: WeatherAPIProtocol {
    private let apiKey: String
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    private let geoBase = "https://api.openweathermap.org/geo/1.0"
    private let session: URLSession

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func fetchCurrentWeather(lat: Double, lon: Double) async throws -> CurrentWeatherResponse {
        guard var components = URLComponents(string: "\(baseURL)/weather") else {
            throw WeatherAPIError.badURL
        }
        components.queryItems = [
            URLQueryItem(name: "lat", value: "\(lat)"),
            URLQueryItem(name: "lon", value: "\(lon)"),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric")
        ]
        guard let url = components.url else { throw WeatherAPIError.badURL }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse else { throw WeatherAPIError.invalidResponse }
            guard (200...299).contains(http.statusCode) else { throw WeatherAPIError.serverError(statusCode: http.statusCode) }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .secondsSince1970
                let decoded = try decoder.decode(CurrentWeatherResponse.self, from: data)
                return decoded
            } catch {
                throw WeatherAPIError.decodingError(error)
            }
        } catch {
            throw WeatherAPIError.requestFailed(error)
        }
    }

    func geocode(city: String, limit: Int) async throws -> [GeocodingResult] {
        guard var components = URLComponents(string: "\(geoBase)/direct") else { throw WeatherAPIError.badURL }
        components.queryItems = [
            URLQueryItem(name: "q", value: city),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "appid", value: apiKey)
        ]
        guard let url = components.url else { throw WeatherAPIError.badURL }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse else { throw WeatherAPIError.invalidResponse }
            guard (200...299).contains(http.statusCode) else { throw WeatherAPIError.serverError(statusCode: http.statusCode) }
            do {
                let decoder = JSONDecoder()
                let decoded = try decoder.decode([GeocodingResult].self, from: data)
                return decoded
            } catch {
                throw WeatherAPIError.decodingError(error)
            }
        } catch {
            throw WeatherAPIError.requestFailed(error)
        }
    }

    func fetchGroup(ids: [Int]) async throws -> [CurrentWeatherResponse] {
        guard !ids.isEmpty else { return [] }
        // OpenWeather 'group' supports up to 20 ids per request; we'll batch
        let batches = stride(from: 0, to: ids.count, by: 20).map { Array(ids[$0..<min($0+20, ids.count)]) }
        var results: [CurrentWeatherResponse] = []
        for batch in batches {
            guard var components = URLComponents(string: "\(baseURL)/group") else { throw WeatherAPIError.badURL }
            let idList = batch.map(String.init).joined(separator: ",")
            components.queryItems = [
                URLQueryItem(name: "id", value: idList),
                URLQueryItem(name: "appid", value: apiKey),
                URLQueryItem(name: "units", value: "metric")
            ]
            guard let url = components.url else { throw WeatherAPIError.badURL }

            do {
                let (data, response) = try await session.data(from: url)
                guard let http = response as? HTTPURLResponse else { throw WeatherAPIError.invalidResponse }
                guard (200...299).contains(http.statusCode) else { throw WeatherAPIError.serverError(statusCode: http.statusCode) }
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .secondsSince1970
                    struct GroupResponse: Codable { let list: [CurrentWeatherResponse] }
                    let group = try decoder.decode(GroupResponse.self, from: data)
                    results.append(contentsOf: group.list)
                } catch {
                    throw WeatherAPIError.decodingError(error)
                }
            } catch {
                throw WeatherAPIError.requestFailed(error)
            }
        }
        return results
    }
}
