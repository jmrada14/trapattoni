import SwiftUI

struct SessionLogDetailView: View {
    let log: SessionLog

    var body: some View {
        List {
            // Header Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.sessionName)
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text(log.formattedDate)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Completion badge
                        if log.completionPercentage >= 1.0 {
                            Label("Completed", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.green.opacity(0.15))
                                .clipShape(Capsule())
                        } else {
                            Label("Partial", systemImage: "circle.lefthalf.filled")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.orange.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Stats Section
            Section("Session Stats") {
                LabeledContent("Duration") {
                    Text(log.actualDurationFormatted)
                }

                LabeledContent("Exercises Completed") {
                    Text("\(log.exercisesCompleted) / \(log.exercisesTotal)")
                }

                if let avgRating = log.averageRating {
                    LabeledContent("Average Rating") {
                        HStack(spacing: 4) {
                            Text(String(format: "%.1f", avgRating))
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                }

                LabeledContent("Completion") {
                    Text("\(Int(log.completionPercentage * 100))%")
                }
            }

            // Ratings Section
            if !log.ratings.isEmpty {
                Section("Exercise Ratings") {
                    ForEach(log.ratings.sorted { $0.ratedAt < $1.ratedAt }) { rating in
                        RatingRow(rating: rating)
                    }
                }
            }
        }
        .navigationTitle("Session Details")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Rating Row

struct RatingRow: View {
    let rating: ExerciseRating

    var body: some View {
        HStack(spacing: 12) {
            CategoryIconView(category: rating.exerciseCategory, size: .small)

            VStack(alignment: .leading, spacing: 2) {
                Text(rating.localizedExerciseName)
                    .font(.subheadline)

                if !rating.notes.isEmpty {
                    Text(rating.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Star display
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating.rating ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundStyle(star <= rating.rating ? .yellow : .secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SessionLogDetailView(log: {
            let session = TrainingSession(name: "Morning Warmup")
            let log = SessionLog(session: session)
            log.complete(exercisesCompleted: 4, actualDuration: 1200)
            return log
        }())
    }
}
