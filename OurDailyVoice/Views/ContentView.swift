//
//  ContentView.swift
//  OurDailyVoice
//
//  Created by Kyu Kim on 1/14/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = MoodViewModel()

    // 3 columns for 3x3 grid
    private let cols = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        ZStack {
            Theme.bgGradient.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                header

                DatePicker("Day", selection: Binding(
                    get: { vm.selectedDay },
                    set: { vm.setDay($0) }
                ), displayedComponents: .date)
                .datePickerStyle(.compact)
                .tint(.white)
                .padding(12)
                .background(.white.opacity(Theme.cardOpacity))
                .clipShape(RoundedRectangle(cornerRadius: Theme.corner))

                Text("Tap your vibe ✨")
                    .font(.headline)
                    .foregroundStyle(.white)

                Picker("Mode", selection: $vm.mode) {
                    Text("Enter").tag(SessionMode.enter)
                    Text("Leave").tag(SessionMode.leave)
                }
                .pickerStyle(.segmented)

                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(MoodPalette.options) { option in
                        Button {
                            vm.logGroup(option: option)
                        } label: {
                            VStack(spacing: 6) {
                                Text(option.emoji)
                                    .font(.system(size: 36))
                                Text("\(option.value)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
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

                statsRow

                logsList

                Spacer()
            }
            .padding()
        }
        .task { await vm.start() }
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("OurDailyVoice")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(.white)
                Text(vm.selectedDay.formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer()
            if vm.isLoading {
                ProgressView().tint(.white)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statPill("Logs", "\(vm.entries.count)")
            statPill("Avg", vm.average.map { String(format: "%.1f", $0) } ?? "—")
            statPill("Top", vm.topEmoji ?? "—")
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

    private var logsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Logs")
                .font(.headline)
                .foregroundStyle(.white)

            if vm.entries.isEmpty {
                Text("No logs yet — tap an emoji.")
                    .foregroundStyle(.white.opacity(0.85))
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(vm.entries) { e in
                            HStack(spacing: 12) {
                                Text(e.emoji).font(.system(size: 28))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Value: \(e.value)")
                                        .foregroundStyle(.white)
                                        .font(.subheadline.weight(.semibold))
                                    Text(e.timestamp.formatted(date: .omitted, time: .shortened))
                                        .foregroundStyle(.white.opacity(0.85))
                                        .font(.caption)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(.white.opacity(Theme.cardOpacity))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.corner))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.corner)
                                    .stroke(.white.opacity(0.14), lineWidth: 1)
                            )
                        }
                    }
                }
                .frame(maxHeight: 220)
            }
        }
    }
}

#Preview {
    ContentView()
}
