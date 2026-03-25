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

            do {
                try await service.appendGroupMoodUsingSelectedClub(
                    day: selectedDay,
                    mode: mode,
                    value: option.value
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

    var dailyAnalytics: [Date: DailyAnalytics] {
        let calendar = Calendar.current

        return Dictionary(
            uniqueKeysWithValues: allSessions.map { session in
                let date = calendar.startOfDay(for: session.day)

                let enter = session.enterValues
                let leave = session.leaveValues

                let enterAvg = enter.isEmpty ? nil : Double(enter.reduce(0, +)) / Double(enter.count)
                let leaveAvg = leave.isEmpty ? nil : Double(leave.reduce(0, +)) / Double(leave.count)

                let result: DailyAnalytics

                switch (enterAvg, leaveAvg) {
                case let (enter?, leave?):
                    result = DailyAnalytics(score: leave - enter, kind: .none)
                case let (enter?, nil):
                    result = DailyAnalytics(score: enter, kind: .enterOnly)
                case let (nil, leave?):
                    result = DailyAnalytics(score: -leave, kind: .leaveOnly)
                case (nil, nil):
                    result = DailyAnalytics(score: 0, kind: .none)
                }

                return (date, result)
            }
        )
    }
}
