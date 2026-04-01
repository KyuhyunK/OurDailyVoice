//
//  Theme.swift
//  OurDailyVoice
//
//  Created by Kyu Kim on 1/14/26.
//

// UI Theme for the app

import SwiftUI


enum Theme {
    static let corner: CGFloat = 20
    static let cardOpacity: Double = 0.25

    static let bgGradient = LinearGradient(
        colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.55), Color.pink.opacity(0.55)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
