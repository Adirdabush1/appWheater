import Foundation
import SwiftData

@Model
final class City {
    @Attribute(.unique) var id: String = UUID().uuidString
    var name: String
    var country: String?
    var lat: Double
    var lon: Double

    // Cached weather fields
    var lastUpdated: Date?
    var temperature: Double?
    var temperatureMin: Double?
    var temperatureMax: Double?
    var humidity: Int?
    var windSpeed: Double?
    var condition: String?
    var icon: String?

    init(name: String, country: String? = nil, lat: Double, lon: Double) {
        self.name = name
        self.country = country
        self.lat = lat
        self.lon = lon
    }
}
