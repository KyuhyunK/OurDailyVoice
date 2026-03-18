//
//  MoodViewModel.swift
//  OurDailyVoice
//
//  Created by Kyu Kim on 1/14/26.
//

// This keeps UI logic out of the View.

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

    private let service = MoodService()
    private var uid: String?

    func start() async {
        do {
            uid = try await service.ensureSignedIn()
            print("UID:", uid ?? "nil")
            try await refresh()
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

    func setDay(_ day: Date) {
        selectedDay = Calendar.current.startOfDay(for: day)
        Task {
            do { try await refresh() }
            catch { errorMessage = error.localizedDescription }
        }
    }

    func log(option: MoodOption) {
        isLoading = true
        Haptics.tap()
        Task {
            defer { isLoading = false }
            do {
                try await service.addMoodUsingSelectedClub(emoji: option.emoji, value: option.value, day: selectedDay)
                Haptics.success()
                try await refresh()
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
                try await service.appendGroupMoodUsingSelectedClub(day: selectedDay, mode: mode, value: option.value)
                Haptics.success()
                try await refresh()
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
    
}
