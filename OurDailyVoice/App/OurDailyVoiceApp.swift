//
//  OurDailyVoiceApp.swift
//  OurDailyVoice
//
//  Created by Kyu Kim on 1/14/26.
//

import SwiftUI
import FirebaseCore

@main
struct OurDailyVoiceApp: App {
    @StateObject private var appState = AppState()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if !appState.isLoggedIn {
                    LoginView()
                } else if appState.selectedSite == nil {
                    ClubPickerView()
                } else {
                    ContentView()
                }
            }
            .environmentObject(appState)
        }
    }
}
