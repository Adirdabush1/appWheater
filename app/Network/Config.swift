import Foundation

/// Centralized configuration for network keys and endpoints.
/// Replace the API key here if you want to keep it out of Info.plist.
struct Config {
    // OpenWeatherMap API key (provided by user)
    static let openWeatherAPIKey = "9aa605d3d2f5f7db65e5f970e7e2d163"
    
    static let favoriteCityIDsUserDefaultsKey = "OPENWEATHER_FAVORITE_CITY_IDS"
    
    /// Reads an optional comma-separated list of city IDs from UserDefaults or Info.plist key `OPENWEATHER_FAVORITE_CITY_IDS`.
    /// If none, returns a default list of major cities.
    static var favoriteCityIDs: [Int] {
        // First, check UserDefaults
        if let rawUD = UserDefaults.standard.string(forKey: favoriteCityIDsUserDefaultsKey), !rawUD.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return rawUD.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        }
        // Then, check Info.plist
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "OPENWEATHER_FAVORITE_CITY_IDS") as? String,
              !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // Return default cities: London, New York, Tokyo, Paris, Sydney
            return [2643743, 5128581, 1850147, 2988507, 2147714]
        }
        return raw.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }
    
    static func persistFavoriteIDs(_ ids: [Int]) {
        let raw = ids.map(String.init).joined(separator: ",")
        UserDefaults.standard.set(raw, forKey: favoriteCityIDsUserDefaultsKey)
    }
}
