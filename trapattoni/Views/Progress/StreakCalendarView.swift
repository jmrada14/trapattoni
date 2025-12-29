import SwiftUI

struct StreakCalendarView: View {
    let trainingDays: Set<DateComponents>

    @State private var currentMonth = Date()

    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return []
        }

        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        var currentDate = monthInterval.start
        while currentDate < monthInterval.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        // Pad to complete the last week
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Training Calendar")
                    .font(.headline)

                Spacer()

                HStack(spacing: 16) {
                    Button {
                        withAnimation {
                            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.caption)
                    }

                    Text(monthTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(minWidth: 120)

                    Button {
                        withAnimation {
                            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .disabled(calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month))
                }
            }

            // Day headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(Array(daysOfWeek.enumerated()), id: \.offset) { _, day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date {
                        CalendarDayView(
                            date: date,
                            isTrainingDay: isTrainingDay(date),
                            isToday: calendar.isDateInToday(date)
                        )
                    } else {
                        Color.clear
                            .frame(height: 32)
                    }
                }
            }

            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Trained")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: 8, height: 8)
                    Text("Today")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func isTrainingDay(_ date: Date) -> Bool {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return trainingDays.contains(components)
    }
}

// MARK: - Calendar Day View

struct CalendarDayView: View {
    let date: Date
    let isTrainingDay: Bool
    let isToday: Bool

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        ZStack {
            if isTrainingDay {
                Circle()
                    .fill(Color.green)
            }

            if isToday {
                Circle()
                    .stroke(Color.blue, lineWidth: 2)
            }

            Text(dayNumber)
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isTrainingDay ? .white : .primary)
        }
        .frame(height: 32)
    }
}

#Preview {
    StreakCalendarView(trainingDays: [
        DateComponents(year: 2025, month: 12, day: 20),
        DateComponents(year: 2025, month: 12, day: 22),
        DateComponents(year: 2025, month: 12, day: 23),
        DateComponents(year: 2025, month: 12, day: 25),
        DateComponents(year: 2025, month: 12, day: 26)
    ])
    .padding()
}
