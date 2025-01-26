//
//  ContentView.swift
//  Apps&Nix
//
//  Created by Stefan Hafensteiner on 26.01.25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // Spiele Tab
            SnakeGame()
                .tabItem {
                    Image(systemName: "gamecontroller")
                    Text("Spiele")
                }

            // Programme Tab
            Text("Programme")
                .tabItem {
                    Image(systemName: "square")
                    Text("Programme")
                }
            
            // Steuerung Tab
            Text("Steuerung")
                .tabItem {
                    Image(systemName: "keyboard")
                    Text("Steuerung")
                }
            
            // Einstellungen Tab
            Text("Einstellungen")
                .tabItem {
                    Image(systemName: "gear")
                    Text("Einstellungen")
                }
        }
    }
}

#Preview {
    ContentView()
}
