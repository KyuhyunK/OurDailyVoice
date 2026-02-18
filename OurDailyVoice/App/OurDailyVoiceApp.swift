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
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
