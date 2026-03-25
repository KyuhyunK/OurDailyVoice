//
//  AdminAnalyticsView.swift
//  OurDailyVoice
//
//  Created by Kyu Kim on 3/24/26.
//

import SwiftUI

enum AnalyticsKind {
    case enterOnly
    case leaveOnly
    case none
}

struct DailyAnalytics {
    let score: Double
    let kind: AnalyticsKind
}

struct AdminAnalyticsView: View {
    let dailyScores: [Date: DailyAnalytics]

    @State private var currentMonth: Date = Date()

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 7)

    var body: some View {
        ZStack {
            Theme.bgGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header
                    weekdayHeader
                    monthGrid
                    legend
                }
                .padding()
            }
        }
        .navigationTitle("Analytics")
    }

    private var header: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.blue)
                    .frame(width: 36, height: 36)
            }

            Spacer()

            Text(monthTitle(for: currentMonth))
                .font(.system(size: 22, weight: .heavy))

            Spacer()

            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.blue)
                    .frame(width: 36, height: 36)
            }
        }
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                Text(day)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(daysForMonthGrid(), id: \.self) { date in
                dayCell(for: date)
            }
        }
    }

    private var legend: some View {
        VStack(spacing: 10) {
            HStack(spacing: 18) {
                legendItem(color: .green, label: "Positive")
                legendItem(color: .red, label: "Negative")
            }

            HStack(spacing: 18) {
                smallSymbolLegend(systemName: "arrow.right.circle.fill", color: .blue, label: "Enter Only")
                smallSymbolLegend(systemName: "arrow.left.circle.fill", color: .orange, label: "Leave Only")
            }
        }
        .padding(.top, 8)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func smallSymbolLegend(systemName: String, color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemName)
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func indicator(for kind: AnalyticsKind) -> some View {
        switch kind {
        case .enterOnly:
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 10))
                .foregroundStyle(.blue)

        case .leaveOnly:
            Image(systemName: "arrow.left.circle.fill")
                .font(.system(size: 10))
                .foregroundStyle(.orange)

        case .none:
            EmptyView()
        }
    }

    @ViewBuilder
    private func dayCell(for date: Date) -> some View {
        let isInCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
        let dayNumber = calendar.component(.day, from: date)
        let analytics = analyticsForDate(date)

        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Text("\(dayNumber)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isInCurrentMonth ? .primary : .secondary)

                if let analytics {
                    indicator(for: analytics.kind)
                }
            }

            if let analytics {
                Text(scoreLabel(analytics.score))
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(scoreColor(analytics.score))
                    )
            } else {
                Text("—")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 88)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardFill(for: analytics?.score, isInCurrentMonth: isInCurrentMonth))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor(for: analytics?.kind), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 3)
        .opacity(isInCurrentMonth ? 1.0 : 0.45)
    }

    private func analyticsForDate(_ date: Date) -> DailyAnalytics? {
        let normalized = calendar.startOfDay(for: date)
        return dailyScores[normalized]
    }

    private func scoreColor(_ score: Double) -> Color {
        if score > 0 { return .green }
        if score < 0 { return .red }
        return .gray
    }
    
    private func borderColor(for kind: AnalyticsKind?) -> Color {
        guard let kind else { return .clear }

        switch kind {
        case .enterOnly:
            return .blue
        case .leaveOnly:
            return .orange
        case .none:
            return .clear
        }
    }

    private func cardFill(for score: Double?, isInCurrentMonth: Bool) -> Color {
        guard isInCurrentMonth else {
            return .white.opacity(0.15)
        }

        guard let score else {
            return .white.opacity(0.20)
        }

        if score > 0 {
            return .green.opacity(0.28)
        } else if score < 0 {
            return .red.opacity(0.28)
        } else {
            return .white.opacity(0.5)
        }
    }

    private func cardStroke(for score: Double?, isInCurrentMonth: Bool) -> Color {
        guard isInCurrentMonth else {
            return .white.opacity(0.08)
        }

        guard let score else {
            return .white.opacity(0.16)
        }

        if score > 0 {
            return .green.opacity(0.45)
        } else if score < 0 {
            return .red.opacity(0.45)
        } else {
            return .white.opacity(0.18)
        }
    }

    private func scoreLabel(_ score: Double) -> String {
        let rounded = String(format: "%.1f", score)
        return score > 0 ? "+\(rounded)" : rounded
    }

    private func monthTitle(for date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }

    private func changeMonth(by value: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) else { return }
        currentMonth = newMonth
    }

    private func daysForMonthGrid() -> [Date] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
            let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
            let lastDay = calendar.date(byAdding: .day, value: -1, to: monthInterval.end),
            let lastWeek = calendar.dateInterval(of: .weekOfMonth, for: lastDay)
        else {
            return []
        }

        var dates: [Date] = []
        var current = firstWeek.start

        while current < lastWeek.end {
            dates.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return dates
    }
}

#Preview {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    let sampleScores: [Date: DailyAnalytics] = [
        today: DailyAnalytics(score: 5.6, kind: .enterOnly),
        calendar.date(byAdding: .day, value: -1, to: today)!: DailyAnalytics(score: 6.0, kind: .enterOnly),
        calendar.date(byAdding: .day, value: -2, to: today)!: DailyAnalytics(score: 7.0, kind: .enterOnly),
        calendar.date(byAdding: .day, value: -3, to: today)!: DailyAnalytics(score: -8.5, kind: .leaveOnly),
        calendar.date(byAdding: .day, value: -7, to: today)!: DailyAnalytics(score: -2.1, kind: .none)
    ]

    NavigationStack {
        AdminAnalyticsView(dailyScores: sampleScores)
    }
}
