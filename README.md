app - Weather Test
===================

Overview
--------
This is an iOS sample app (Swift/SwiftUI + SwiftData) that demonstrates fetching and caching weather data from OpenWeatherMap. The app shows a list of cities with current weather and a detail screen with additional fields.

Quick features
--------------
- City list with current temperature, icon, H/L (max/min) temperatures and wind speed.
- Detail screen with Max, Min, Humidity, Wind, last-updated and a Refresh button.
- Networking via `URLSession` implementation in `app/Network/WeatherAPI.swift`.
- Local caching using SwiftData `City` model (`app/Models/City.swift`).
- Offline banner when network is unavailable (`app/Network/NetworkMonitor.swift`).
- MVVM: `WeatherListViewModel` drives network/persistence logic.

How to run
----------
1. Open the Xcode project: `app/app.xcodeproj`.
2. Update the OpenWeather API key in `app/Network/Config.swift` if needed (currently set to the provided key).
3. Build & run on a Simulator or device (iOS 17+/Xcode 15+ recommended).

Notes about architecture
------------------------
- Simple MVVM: `WeatherListViewModel` exposes `@Published` properties and performs network + persistence operations. Views are SwiftUI views (`WeatherListView`, `WeatherDetailView`).
- Persistence uses SwiftData (@Model `City`) for cached fields (temp, min/max/humidity/wind/icon/lastUpdated).
- Network module `WeatherAPI` handles REST calls and decoding of OpenWeather responses.

What's included / test checklist
--------------------------------
- Main list: shows city name, current temp, icon, min/max temp and wind speed. (Done)
- Detail screen: shows max, min temp, humidity, wind, Refresh button with 1.5s minimum visible state. (Done)
- Network requests with URLSession. (Done)
- Local save of last data using SwiftData. (Done)
- Offline support & banner. (Done)
- Error handling and alerts on failure. (Done)
- MVVM architecture used. (Done)

Notes & next steps
------------------
- README did not previously exist; added now for repo submission.
- If you want, I can add a short document answering the theoretical questions included in the test instructions.

Contact
-------
If push fails due to authentication, ensure your machine has git credentials set up (SSH key or GitHub credentials) and that the target repository URL is correct.

