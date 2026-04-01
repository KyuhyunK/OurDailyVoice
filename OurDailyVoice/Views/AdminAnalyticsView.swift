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

struct DailyAnalytics: Identifiable {
    let id = UUID()
    let day: Date
    let score: Double
    let kind: AnalyticsKind
    let youthsServed: Int
    let durationText: String
    let roomName: String
}

struct RoomSummary: Identifiable {
    let id = UUID()
    let room: String
    let youths: Int
    let avgScore: Double?
    let avgDurationMinutes: Double?
    let days: Int
}

struct AdminAnalyticsView: View {
    let dailyScores: [DailyAnalytics]
    let siteName: String
    let availableRooms: [String]

    @State private var currentMonth: Date
    @State private var selectedStartDate: Date
    @State private var selectedEndDate: Date
    @State private var selectedRooms: Set<String> = []

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 7)
    private let dashboardColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

    init(
        dailyScores: [DailyAnalytics],
        siteName: String,
        availableRooms: [String]
    ) {
        self.dailyScores = dailyScores
        self.siteName = siteName
        self.availableRooms = availableRooms

        let sortedDates = dailyScores
            .map { Calendar.current.startOfDay(for: $0.day) }
            .sorted()

        let defaultStart = sortedDates.first ?? Calendar.current.startOfDay(for: Date())
        let defaultEnd = sortedDates.last ?? Calendar.current.startOfDay(for: Date())

        _selectedStartDate = State(initialValue: defaultStart)
        _selectedEndDate = State(initialValue: defaultEnd)
        _currentMonth = State(initialValue: defaultEnd)
    }

    var body: some View {
        ZStack {
            Theme.bgGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    filtersSection
                    kpiSection
                    trendSection
                    calendarSection
                    roomBreakdownSection
                }
                .padding()
            }
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Filters

    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filters")
                .font(.system(size: 28 * uiScale, weight: .heavy))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Site")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(1))

                    Text(siteName)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }

                HStack(spacing: 12) {
                    DatePicker(
                        "From",
                        selection: Binding(
                            get: { selectedStartDate },
                            set: { newValue in
                                selectedStartDate = calendar.startOfDay(for: newValue)
                                if selectedStartDate > selectedEndDate {
                                    selectedEndDate = selectedStartDate
                                }
                            }
                        ),
                        displayedComponents: .date
                    )

                    DatePicker(
                        "To",
                        selection: Binding(
                            get: { selectedEndDate },
                            set: { newValue in
                                selectedEndDate = calendar.startOfDay(for: newValue)
                                if selectedEndDate < selectedStartDate {
                                    selectedStartDate = selectedEndDate
                                }
                            }
                        ),
                        displayedComponents: .date
                    )
                }
                .tint(.white)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Rooms")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))

                    roomSelector
                }
            }
            .padding(16)
            .background(.white.opacity(Theme.cardOpacity))
            .clipShape(RoundedRectangle(cornerRadius: Theme.corner))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.corner)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
        }
    }

    private var roomSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    if selectedRooms.count == availableRooms.count {
                        selectedRooms.removeAll()
                    } else {
                        selectedRooms = Set(availableRooms)
                    }
                } label: {
                    Text(selectedRooms.count == availableRooms.count ? "Clear All" : "All Rooms")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.white.opacity(selectedRooms.isEmpty ? 0.30 : 0.20))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                ForEach(availableRooms, id: \.self) { room in
                    Button {
                        if selectedRooms.contains(room) {
                            selectedRooms.remove(room)
                        } else {
                            selectedRooms.insert(room)
                        }
                    } label: {
                        Text(room)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                selectedRooms.contains(room)
                                    ? .white.opacity(0.32)
                                    : .white.opacity(0.16)
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(.white.opacity(selectedRooms.contains(room) ? 0.45 : 0.12), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Dashboard Data

    private var filteredEntries: [DailyAnalytics] {
        let start = calendar.startOfDay(for: selectedStartDate)
        let end = calendar.startOfDay(for: selectedEndDate)

        return dailyScores.filter { entry in
            let day = calendar.startOfDay(for: entry.day)
            let matchesDate = day >= start && day <= end
            let matchesRoom = selectedRooms.isEmpty || selectedRooms.contains(entry.roomName)
            return matchesDate && matchesRoom
        }
    }

    private var totalYouthsServed: Int {
        filteredEntries.reduce(0) { $0 + $1.youthsServed }
    }

    private var averageScore: Double? {
        guard !filteredEntries.isEmpty else { return nil }
        let total = filteredEntries.reduce(0.0) { $0 + $1.score }
        return total / Double(filteredEntries.count)
    }

    private var averageDurationMinutes: Double? {
        let durations = filteredEntries.compactMap { parseDurationMinutes($0.durationText) }
        guard !durations.isEmpty else { return nil }
        return durations.reduce(0, +) / Double(durations.count)
    }

    private var activeDaysCount: Int {
        filteredEntries.count
    }

    private var enterOnlyCount: Int {
        filteredEntries.filter { $0.kind == .enterOnly }.count
    }

    private var leaveOnlyCount: Int {
        filteredEntries.filter { $0.kind == .leaveOnly }.count
    }

    private var bestDay: DailyAnalytics? {
        filteredEntries.max { $0.score < $1.score }
    }

    private var lowestDay: DailyAnalytics? {
        filteredEntries.min { $0.score < $1.score }
    }

    private var roomSummaries: [RoomSummary] {
        let grouped = Dictionary(grouping: filteredEntries, by: { $0.roomName })

        return grouped.map { room, entries in
            let totalYouths = entries.reduce(0) { $0 + $1.youthsServed }

            let avgScore: Double? = {
                guard !entries.isEmpty else { return nil }
                let total = entries.reduce(0.0) { $0 + $1.score }
                return total / Double(entries.count)
            }()

            let durations = entries.compactMap { parseDurationMinutes($0.durationText) }
            let avgDuration = durations.isEmpty ? nil : durations.reduce(0, +) / Double(durations.count)

            return RoomSummary(
                room: room,
                youths: totalYouths,
                avgScore: avgScore,
                avgDurationMinutes: avgDuration,
                days: entries.count
            )
        }
        .sorted { $0.room.localizedCaseInsensitiveCompare($1.room) == .orderedAscending }
    }

    // MARK: - Sections

    private var kpiSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.system(size: 28 * uiScale, weight: .heavy))
                .foregroundStyle(.white)

            LazyVGrid(columns: dashboardColumns, spacing: 12) {
                dashboardCard(
                    title: "Youths Served",
                    value: "\(totalYouthsServed)",
                    subtitle: "Across selected days"
                )

                dashboardCard(
                    title: "Avg Mood Change",
                    value: averageScore.map { scoreLabel($0) } ?? "—",
                    subtitle: "Filtered date range"
                )

                dashboardCard(
                    title: "Avg Duration",
                    value: averageDurationMinutes.map { formatDuration(minutes: $0) } ?? "—",
                    subtitle: "Average program time"
                )

                dashboardCard(
                    title: "Active Days",
                    value: "\(activeDaysCount)",
                    subtitle: "Days with recorded data"
                )
            }
        }
    }

    private func dashboardCard(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))

            Text(value)
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white.opacity(Theme.cardOpacity))
        .clipShape(RoundedRectangle(cornerRadius: Theme.corner))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trend Summary")
                .font(.system(size: 28 * uiScale, weight: .heavy))
                .foregroundStyle(.white)

            VStack(spacing: 10) {
                statRow(
                    label: "Best Day",
                    value: bestDay.map { "\(formattedShortDate($0.day)) • \(scoreLabel($0.score))" } ?? "—"
                )

                statRow(
                    label: "Lowest Day",
                    value: lowestDay.map { "\(formattedShortDate($0.day)) • \(scoreLabel($0.score))" } ?? "—"
                )

                statRow(label: "Enter-Only Days", value: "\(enterOnlyCount)")
                statRow(label: "Leave-Only Days", value: "\(leaveOnlyCount)")
            }
            .padding(16)
            .background(.white.opacity(Theme.cardOpacity))
            .clipShape(RoundedRectangle(cornerRadius: Theme.corner))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.corner)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))

            Spacer()

            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
        }
    }

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calendar")
                .font(.system(size: 28 * uiScale, weight: .heavy))
                .foregroundStyle(.white)

            VStack(spacing: 20) {
                header
                weekdayHeader
                monthGrid
                legend
            }
            .padding(16)
            .background(.white.opacity(Theme.cardOpacity))
            .clipShape(RoundedRectangle(cornerRadius: Theme.corner))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.corner)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
        }
    }

    private var roomBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Room Breakdown")
                .font(.system(size: 28 * uiScale, weight: .heavy))
                .foregroundStyle(.white)

            if roomSummaries.isEmpty {
                Text("No room data for the selected filters.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.82))
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(Theme.cardOpacity))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.corner))
            } else {
                VStack(spacing: 10) {
                    ForEach(roomSummaries) { summary in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(summary.room)
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.white)

                                Text("\(summary.days) active days")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.72))
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(summary.youths) youths")
                                    .font(.subheadline.weight(.heavy))
                                    .foregroundStyle(.white)

                                Text(summary.avgScore.map { "Avg \(scoreLabel($0))" } ?? "Avg —")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.78))

                                Text(summary.avgDurationMinutes.map { formatDuration(minutes: $0) } ?? "—")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.78))
                            }
                        }
                        .padding(14)
                        .background(.white.opacity(Theme.cardOpacity))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.corner))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.corner)
                                .stroke(.white.opacity(0.12), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Calendar Components

    private var header: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.16))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(monthTitle(for: currentMonth))
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(.white)

            Spacer()

            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.16))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                Text(day)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.78))
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
                .foregroundStyle(.white.opacity(0.78))
        }
    }

    private func smallSymbolLegend(systemName: String, color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemName)
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.78))
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
                    .foregroundStyle(.white)

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

                VStack(spacing: 4) {
                    Text("\(analytics.youthsServed) youths")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)

                    Text(analytics.durationText)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
            } else {
                Text("—")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 118)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardFill(for: analytics?.score, isInCurrentMonth: isInCurrentMonth))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor(for: analytics?.kind), lineWidth: 2)
        )
        .opacity(isInCurrentMonth ? 1.0 : 0.35)
    }

    // MARK: - Helpers
    
    private let uiScale: CGFloat = 1.12

    private var sectionFill: Color {
        .white.opacity(0.20)
    }

    private var sectionStroke: Color {
        .white.opacity(0.18)
    }

    private var cardFillColor: Color {
        .white.opacity(0.18)
    }

    private var cardStrokeColor: Color {
        .white.opacity(0.14)
    }

    private func analyticsForDate(_ date: Date) -> DailyAnalytics? {
        let normalized = calendar.startOfDay(for: date)

        let matches = filteredEntries.filter {
            calendar.isDate($0.day, inSameDayAs: normalized)
        }

        guard !matches.isEmpty else { return nil }

        if matches.count == 1 {
            return matches[0]
        }

        let totalYouths = matches.reduce(0) { $0 + $1.youthsServed }
        let avgScore = matches.map(\.score).reduce(0, +) / Double(matches.count)

        return DailyAnalytics(
            day: normalized,
            score: avgScore,
            kind: .none,
            youthsServed: totalYouths,
            durationText: "Multiple",
            roomName: "All Rooms"
        )
    }

    private func scoreColor(_ score: Double) -> Color {
        if score > 0 { return .green }
        if score < 0 { return .red }
        return .gray
    }

    private func borderColor(for kind: AnalyticsKind?) -> Color {
        guard let kind else { return .white.opacity(0.08) }

        switch kind {
        case .enterOnly:
            return .blue.opacity(0.75)
        case .leaveOnly:
            return .orange.opacity(0.75)
        case .none:
            return .white.opacity(0.08)
        }
    }

    private func cardFill(for score: Double?, isInCurrentMonth: Bool) -> Color {
        guard isInCurrentMonth else {
            return .white.opacity(0.08)
        }

        guard let score else {
            return .white.opacity(0.15)
        }

        if score > 0 {
            return .green.opacity(0.26)
        } else if score < 0 {
            return .red.opacity(0.26)
        } else {
            return .white.opacity(0.20)
        }
    }

    private func scoreLabel(_ score: Double) -> String {
        let rounded = String(format: "%.1f", score)
        return score > 0 ? "+\(rounded)" : rounded
    }

    private func monthTitle(for date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }

    private func formattedShortDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
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

    private func parseDurationMinutes(_ text: String) -> Double? {
        guard text != "—" else { return nil }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: " ")

        if parts.count == 2,
           let hours = Int(parts[0].replacingOccurrences(of: "h", with: "")),
           let minutes = Int(parts[1].replacingOccurrences(of: "m", with: "")) {
            return Double(hours * 60 + minutes)
        }

        if parts.count == 1,
           let minutes = Int(parts[0].replacingOccurrences(of: "m", with: "")) {
            return Double(minutes)
        }

        return nil
    }

    private func formatDuration(minutes: Double) -> String {
        let totalMinutes = Int(minutes.rounded())
        let hours = totalMinutes / 60
        let remainingMinutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes)m"
        }
    }
}

#Preview {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    let sampleScores: [DailyAnalytics] = [
        DailyAnalytics(
            day: today,
            score: 5.6,
            kind: .enterOnly,
            youthsServed: 24,
            durationText: "2h 10m",
            roomName: "Dreamerville"
        ),
        DailyAnalytics(
            day: calendar.date(byAdding: .day, value: -1, to: today)!,
            score: 6.0,
            kind: .enterOnly,
            youthsServed: 19,
            durationText: "1h 45m",
            roomName: "Dreamerville"
        ),
        DailyAnalytics(
            day: calendar.date(byAdding: .day, value: -2, to: today)!,
            score: 7.0,
            kind: .enterOnly,
            youthsServed: 21,
            durationText: "2h 00m",
            roomName: "Teen Tech Center"
        ),
        DailyAnalytics(
            day: calendar.date(byAdding: .day, value: -3, to: today)!,
            score: -8.5,
            kind: .leaveOnly,
            youthsServed: 17,
            durationText: "1h 20m",
            roomName: "Music Studio"
        ),
        DailyAnalytics(
            day: calendar.date(byAdding: .day, value: -7, to: today)!,
            score: -2.1,
            kind: .none,
            youthsServed: 15,
            durationText: "—",
            roomName: "Dreamerville"
        )
    ]

    NavigationStack {
        AdminAnalyticsView(
            dailyScores: sampleScores,
            siteName: "Andrew Jackson",
            availableRooms: [
                "Dreamerville",
                "Teen Tech Center",
                "Music Studio",
                "Art Room"
            ]
        )
    }
}
