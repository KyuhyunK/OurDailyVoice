//
//  ContentView.swift
//  OurDailyVoice
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm = MoodViewModel()
    @State private var showAdminAnalytics = false

    private let cols = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        currentSelectionSection
                        dayPickerSection

                        Text("Tap your vibe ✨")
                            .font(.headline)
                            .foregroundStyle(.white)

                        modePickerSection
                        moodGridSection
                        statsRow
                        logsList

                        Spacer(minLength: 24)
                    }
                    .padding()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { navigationBarContent }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showAdminAnalytics) {
                AdminAnalyticsView(
                    dailyScores: vm.dailyAnalytics,
                    siteName: appState.selectedSite?.name ?? "Unknown Site",
                    availableRooms: appState.selectedSite?.rooms ?? []
                )
            }
        }.onAppear {
            vm.appState = appState
        }
        .task { await vm.start() }
        .alert(
            "Error",
            isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - NAV BAR

    @ToolbarContentBuilder
    private var navigationBarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Button {
                    Haptics.tap()
                    appState.selectedRoom = nil
                } label: {
                    Label("Change Room", systemImage: "door.left.hand.open")
                }

                Button {
                    Haptics.tap()
                    appState.selectedRoom = nil
                    appState.selectedSite = nil
                } label: {
                    Label("Change Site", systemImage: "building.2")
                }

                Button {
                    Haptics.tap()
                    showAdminAnalytics = true
                } label: {
                    Label("Admin Analytics", systemImage: "chart.bar")
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(12)
            }
        }
    }

    // MARK: - TOP INFO

    private var currentSelectionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(appState.selectedSite?.name ?? "No Site Selected")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            Text(appState.selectedRoom ?? "No Room Selected")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    // MARK: - SECTIONS

    private var dayPickerSection: some View {
        DatePicker(
            "Choose Date",
            selection: Binding(
                get: { vm.selectedDay },
                set: { vm.setDay($0) }
            ),
            displayedComponents: .date
        )
        .datePickerStyle(.compact)
        .tint(.white)
        .padding(12)
        .background(.white.opacity(Theme.cardOpacity))
        .clipShape(RoundedRectangle(cornerRadius: Theme.corner))
    }

    private var modePickerSection: some View {
        Picker("Mode", selection: $vm.mode) {
            Text("Enter").tag(SessionMode.enter)
            Text("Leave").tag(SessionMode.leave)
        }
        .pickerStyle(.segmented)
    }

    private var moodGridSection: some View {
        LazyVGrid(columns: cols, spacing: 15) {
            ForEach(MoodPalette.options) { option in
                Button {
                    Haptics.tap()
                    vm.logGroup(option: option)
                } label: {
                    VStack(spacing: 6) {
                        Text(option.emoji)
                            .font(.system(size: 40))

                        Text("\(option.value)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(.white.opacity(Theme.cardOpacity))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.corner))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.corner)
                            .stroke(.white.opacity(0.18), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - HELPERS

    private var statsRow: some View {
        let values = vm.mode == .enter
            ? (vm.session?.enterValues ?? [])
            : (vm.session?.leaveValues ?? [])

        return HStack(spacing: 15) {
            statPill("Logs", "\(values.count)")
            statPill("Avg", vm.average.map { String(format: "%.1f", $0) } ?? "—")
            statPill("Top", vm.topEmoji ?? "—")
            statPill("Youths", "\(vm.youthsServed)")
            statPill("Duration", vm.formattedProgramDuration)
        }
    }

    private func statPill(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))

            Text(value)
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(.white.opacity(Theme.cardOpacity))
        .clipShape(RoundedRectangle(cornerRadius: Theme.corner))
    }

    private func emojiForValue(_ value: Int) -> String {
        MoodPalette.options.first(where: { $0.value == value })?.emoji ?? "🙂"
    }

    private var logsList: some View {
        let values = vm.mode == .enter
            ? (vm.session?.enterValues ?? [])
            : (vm.session?.leaveValues ?? [])

        let displayedValues = Array(values.reversed())

        return VStack(alignment: .leading, spacing: 8) {
            Text("Logs")
                .font(.headline)
                .foregroundStyle(.white)

            if displayedValues.isEmpty {
                Text("No logs yet — tap an emoji.")
                    .foregroundStyle(.white.opacity(0.85))
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(Array(displayedValues.enumerated()), id: \.offset) { index, value in
                            HStack(spacing: 15) {
                                Text(emojiForValue(value))
                                    .font(.system(size: 30))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Value: \(value)")
                                        .foregroundStyle(.white)
                                        .font(.subheadline.weight(.semibold))

                                    Text("Log \(displayedValues.count - index)")
                                        .foregroundStyle(.white.opacity(0.85))
                                        .font(.caption)
                                }

                                Spacer()
                            }
                            .padding(12)
                            .background(.white.opacity(Theme.cardOpacity))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.corner))
                        }
                    }
                }
                .frame(maxHeight: 220)
            }
        }
    }
}
