import Foundation

struct CurrentWeatherResponse: Codable {
    let coord: Coord
    let weather: [Weather]
    let main: Main
    let wind: Wind?
    let dt: TimeInterval
    let sys: Sys?
    let name: String

    struct Coord: Codable {
        let lon: Double
        let lat: Double
    }
    struct Weather: Codable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }
    struct Main: Codable {
        let temp: Double
        let feels_like: Double?
        let temp_min: Double?
        let temp_max: Double?
        let humidity: Int?
    }
    struct Wind: Codable {
        let speed: Double?
        let deg: Int?
    }
    struct Sys: Codable {
        let country: String?
    }
}

// One Call API 3.0 response structures
struct OneCallResponse: Codable {
    let lat: Double
    let lon: Double
    let timezone: String
    let timezone_offset: Int
    let current: OneCallCurrent
}

struct OneCallCurrent: Codable {
    let dt: TimeInterval
    let sunrise: TimeInterval?
    let sunset: TimeInterval?
    let temp: Double
    let feels_like: Double
    let pressure: Int
    let humidity: Int
    let dew_point: Double
    let uvi: Double
    let clouds: Int
    let visibility: Int
    let wind_speed: Double
    let wind_deg: Int
    let weather: [CurrentWeatherResponse.Weather]
}

// Geocoding API response
struct GeocodingResult: Codable {
    let name: String
    let local_names: [String: String]?
    let lat: Double
    let lon: Double
    let country: String
    let state: String?
}
