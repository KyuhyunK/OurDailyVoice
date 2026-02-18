//
//  SessionDay.swift
//  OurDailyVoice
//
//  Created by Kyu Kim on 2/18/26.
//

import Foundation
import FirebaseFirestore

enum SessionMode: String {
    case enter
    case leave
}

struct SessionDay: Identifiable {
    let id: String           // yyyy-MM-dd
    let day: Date

    let enterValues: [Int]
    let leaveValues: [Int]
    let enterAvg: Double?
    let leaveAvg: Double?
    let delta: Double?

    static func dayId(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Calendar.current.startOfDay(for: date))
    }

    init?(doc: DocumentSnapshot) {
        let data = doc.data() ?? [:]
        let dayTS = data["day"] as? Timestamp ?? Timestamp(date: Date())

        self.id = doc.documentID
        self.day = dayTS.dateValue()

        self.enterValues = data["enterValues"] as? [Int] ?? []
        self.leaveValues = data["leaveValues"] as? [Int] ?? []
        self.enterAvg = data["enterAvg"] as? Double
        self.leaveAvg = data["leaveAvg"] as? Double
        self.delta = data["delta"] as? Double
    }
}
