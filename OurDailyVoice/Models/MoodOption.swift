//
//  MoodOption.swift
//  OurDailyVoice
//
//  Created by Kyu Kim on 1/14/26.
//

// Emoji Choices

import Foundation

struct MoodOption: Identifiable, Hashable {
    let id = UUID()
    let emoji: String
    let value: Int   // 1–9 (10-point scale)
    let label: String
}


// Can edit based on goals:
    // should it be a gradient (happy to sad) or more expressive with other emotions as well?
enum MoodPalette {
    static let options: [MoodOption] = [
        .init(emoji: "😭", value: 1, label: "Awful"),
        .init(emoji: "😢", value: 2, label: "Very Bad"),
        .init(emoji: "🙁", value: 3, label: "Bad"),
        .init(emoji: "😐", value: 4, label: "Meh"),
        .init(emoji: "🙂", value: 5, label: "Okay"),
        .init(emoji: "😊", value: 6, label: "Good"),
        .init(emoji: "😄", value: 7, label: "Great"),
        .init(emoji: "🤩", value: 8, label: "Amazing"),
        .init(emoji: "🔥", value: 9, label: "On Fire")
    ]
}
