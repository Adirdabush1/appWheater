//
//  ContentView.swift
//  app
//
//  Created by rentamac on 1/20/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            WeatherListView()
        }
        .onAppear {
            // Ensure model context is set in the WeatherListView on appear (it reads from Environment)
        }
    }
}

#Preview {
    // Provide an in-memory ModelContainer for previews that includes City
    ContentView()
        .modelContainer(for: [Item.self, City.self], inMemory: true)
}
