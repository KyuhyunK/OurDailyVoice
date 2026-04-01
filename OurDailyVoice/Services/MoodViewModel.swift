//
//  MoodViewModel.swift
//  OurDailyVoice
//
//  Created by Kyu Kim on 1/14/26.
//

import Foundation
import SwiftUI

@MainActor
final class MoodViewModel: ObservableObject {
    @Published var selectedDay: Date = Calendar.current.startOfDay(for: Date())
    @Published var entries: [MoodEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var mode: SessionMode = .enter
    @Published var session: SessionDay?
    @Published var allSessions: [SessionDay] = []
    @Published var appState: AppState?

    private let service = MoodService()
    private var uid: String?

    func start() async {
        do {
            uid = try await service.ensureSignedIn()
            print("UID:", uid ?? "nil")
            try await refresh()
            try await refreshAnalytics()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async throws {
        isLoading = true
        defer { isLoading = false }

        entries = try await service.fetchMoodsForDayUsingSelectedClub(day: selectedDay)
        session = try await service.fetchSessionDayUsingSelectedClub(day: selectedDay)
    }

    func refreshAnalytics() async throws {
        allSessions = try await service.fetchAllSessionDaysUsingSelectedClub()
    }

    func setDay(_ day: Date) {
        selectedDay = Calendar.current.startOfDay(for: day)
        Task {
            do {
                try await refresh()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func log(option: MoodOption) {
        isLoading = true
        Haptics.tap()

        Task {
            defer { isLoading = false }

            do {
                try await service.addMoodUsingSelectedClub(
                    emoji: option.emoji,
                    value: option.value,
                    day: selectedDay
                )
                Haptics.success()
                try await refresh()
                try await refreshAnalytics()
            } catch {
                Haptics.error()
                errorMessage = error.localizedDescription
            }
        }
    }

    func logGroup(option: MoodOption) {
        isLoading = true
        Haptics.tap()

        Task {
            defer { isLoading = false }

            guard let room = appState?.selectedRoom else {
                errorMessage = "No room selected."
                return
            }

            do {
                try await service.appendGroupMoodUsingSelectedClub(
                    day: selectedDay,
                    mode: mode,
                    value: option.value,
                    room: room
                )

                Haptics.success()
                try await refresh()
                try await refreshAnalytics()
            } catch {
                Haptics.error()
                errorMessage = error.localizedDescription
            }
        }
    }

    var average: Double? {
        let values = mode == .enter
            ? (session?.enterValues ?? [])
            : (session?.leaveValues ?? [])

        guard !values.isEmpty else { return nil }
        let sum = values.reduce(0, +)
        return Double(sum) / Double(values.count)
    }

    var topEmoji: String? {
        let values = mode == .enter
            ? (session?.enterValues ?? [])
            : (session?.leaveValues ?? [])

        guard !values.isEmpty else { return nil }

        var counts: [Int: Int] = [:]
        for value in values {
            counts[value, default: 0] += 1
        }

        guard let topValue = counts.max(by: { $0.value < $1.value })?.key else {
            return nil
        }

        return MoodPalette.options.first(where: { $0.value == topValue })?.emoji
    }
    
    private func averageDate(from dates: [Date]) -> Date? {
        guard !dates.isEmpty else { return nil }
        let avg = dates.map(\.timeIntervalSince1970).reduce(0, +) / Double(dates.count)
        return Date(timeIntervalSince1970: avg)
    }

    private func formattedDuration(from start: Date?, to end: Date?) -> String {
        guard let start, let end else { return "—" }

        let duration = end.timeIntervalSince(start)
        guard duration >= 0 else { return "—" }

        let totalMinutes = Int(duration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var dailyAnalytics: [DailyAnalytics] {
        allSessions.map { session in
            let enter = session.enterValues
            let leave = session.leaveValues

            let enterAvg = enter.isEmpty ? nil : Double(enter.reduce(0, +)) / Double(enter.count)
            let leaveAvg = leave.isEmpty ? nil : Double(leave.reduce(0, +)) / Double(leave.count)

            let youthsServed = max(session.enterValues.count, session.leaveValues.count)
            let durationText = formattedDuration(
                from: averageDate(from: session.enterTimestamps),
                to: averageDate(from: session.leaveTimestamps)
            )

            switch (enterAvg, leaveAvg) {
            case let (enter?, leave?):
                return DailyAnalytics(
                    day: session.day,
                    score: leave - enter,
                    kind: .none,
                    youthsServed: youthsServed,
                    durationText: durationText,
                    roomName: session.room
                )
            case let (enter?, nil):
                return DailyAnalytics(
                    day: session.day,
                    score: enter,
                    kind: .enterOnly,
                    youthsServed: youthsServed,
                    durationText: durationText,
                    roomName: session.room
                )
            case let (nil, leave?):
                return DailyAnalytics(
                    day: session.day,
                    score: -leave,
                    kind: .leaveOnly,
                    youthsServed: youthsServed,
                    durationText: durationText,
                    roomName: session.room
                )
            case (nil, nil):
                return DailyAnalytics(
                    day: session.day,
                    score: 0,
                    kind: .none,
                    youthsServed: youthsServed,
                    durationText: durationText,
                    roomName: session.room
                )
            }
        }
    }
    
    var youthsServed: Int {
        let enterCount = session?.enterValues.count ?? 0
        let leaveCount = session?.leaveValues.count ?? 0
        return max(enterCount, leaveCount)
    }

    var averageEnterTime: Date? {
        averageDate(from: session?.enterTimestamps ?? [])
    }

    var averageLeaveTime: Date? {
        averageDate(from: session?.leaveTimestamps ?? [])
    }


    var programDuration: TimeInterval? {
        guard
            let enterAvg = averageEnterTime,
            let leaveAvg = averageLeaveTime
        else { return nil }

        return leaveAvg.timeIntervalSince(enterAvg)
    }

    var formattedProgramDuration: String {
        guard let duration = programDuration, duration >= 0 else { return "—" }

        let totalMinutes = Int(duration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

}
