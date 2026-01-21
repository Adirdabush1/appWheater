import Foundation

/// Centralized configuration for network keys and endpoints.
/// Replace the API key here if you want to keep it out of Info.plist.
struct Config {
    // OpenWeatherMap API key — load from Secrets.plist (gitignored) or Info.plist.
    static var openWeatherAPIKey: String {
        // 1. Try Secrets.plist at app bundle root (untracked by git)
        if let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
           let key = dict["OPENWEATHER_API_KEY"] as? String,
           !key.isEmpty {
            return key
        }

        // 2. Fallback to Info.plist entry if present
        if let infoKey = Bundle.main.object(forInfoDictionaryKey: "OPENWEATHER_API_KEY") as? String,
           !infoKey.isEmpty {
            return infoKey
        }

        // 3. As a last resort, return empty string and log a warning
        #if DEBUG
        print("Warning: OPENWEATHER_API_KEY not found in Secrets.plist or Info.plist")
        #endif
        return ""
    }
    
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
