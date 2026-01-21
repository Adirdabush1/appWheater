//
//  appTests.swift
//  appTests
//
//  Created by rentamac on 1/20/26.
//

import XCTest
@testable import app

final class WeatherDecodingTests: XCTestCase {
    func testCurrentWeatherDecoding() throws {
        let json = """
        {
          "coord": { "lon": -0.13, "lat": 51.51 },
          "weather": [ { "id": 800, "main": "Clear", "description": "clear sky", "icon": "01d" } ],
          "main": { "temp": 15.5, "feels_like": 15.0, "temp_min": 14.0, "temp_max": 16.0, "humidity": 60 },
          "wind": { "speed": 3.6, "deg": 200 },
          "dt": 1620918000,
          "sys": { "country": "GB" },
          "name": "London"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let resp = try decoder.decode(CurrentWeatherResponse.self, from: json)

        XCTAssertEqual(resp.name, "London")
        XCTAssertEqual(resp.coord.lat, 51.51)
        XCTAssertEqual(resp.main.temp, 15.5)
        XCTAssertEqual(resp.weather.first?.icon, "01d")
    }
}
