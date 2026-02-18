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
        guard let uid else { return }
        isLoading = true
        defer { isLoading = false }
        entries = try await service.fetchMoodsForDayUsingSelectedClub(day: selectedDay)
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
                guard let uid else { return }
                try await service.addMoodUsingSelectedClub(emoji: option.emoji, value: option.value, day: selectedDay)
                Haptics.success()
                try await refresh()
            } catch {
                Haptics.error()
                errorMessage = error.localizedDescription
            }
        }
    }

    var average: Double? {
        guard !entries.isEmpty else { return nil }
        let sum = entries.reduce(0) { $0 + $1.value }
        return Double(sum) / Double(entries.count)
    }

    var topEmoji: String? {
        guard !entries.isEmpty else { return nil }
        var counts: [String: Int] = [:]
        for e in entries { counts[e.emoji, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key
    }
    
    
}
