import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Bindable var exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TrainingSession.updatedAt, order: .reverse)
    private var sessions: [TrainingSession]

    @State private var showingStartExercise = false
    @State private var showingAddToSession = false
    @State private var quickSession: TrainingSession?

    private var templateSessions: [TrainingSession] {
        sessions.filter { $0.isTemplate }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header section
                headerSection

                // Tactical board visualization
                TacticalBoardSection(exercise: exercise)

                // Video section
                if let videoURL = exercise.videoURL, !videoURL.isEmpty {
                    VideoPlayerView(urlString: videoURL)
                        .frame(height: 220)
                }

                // Metadata grid
                metadataSection

                // Equipment section
                if !exercise.equipment.isEmpty {
                    equipmentSection
                }

                // Coaching points
                if !exercise.coachingPoints.isEmpty {
                    coachingPointsSection
                }

                // Common mistakes
                if !exercise.commonMistakes.isEmpty {
                    commonMistakesSection
                }

                // Variations
                if !exercise.variations.isEmpty {
                    variationsSection
                }

                // Tags
                if !exercise.tags.isEmpty {
                    tagsSection
                }
            }
            .padding()
        }
        .navigationTitle(exercise.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        startExercise()
                    } label: {
                        Label("Start Exercise", systemImage: "play.fill")
                    }

                    Button {
                        showingAddToSession = true
                    } label: {
                        Label("Add to Session", systemImage: "plus.circle")
                    }

                    Divider()

                    Button {
                        exercise.isFavorite.toggle()
                    } label: {
                        Label(
                            exercise.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                            systemImage: exercise.isFavorite ? "heart.slash" : "heart"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        #if os(iOS)
        .fullScreenCover(item: $quickSession) { session in
            SessionExecutionView(session: session)
        }
        #else
        .sheet(item: $quickSession) { session in
            SessionExecutionView(session: session)
                .frame(minWidth: 600, minHeight: 500)
        }
        #endif
        .sheet(isPresented: $showingAddToSession) {
            AddExerciseToSessionSheet(exercise: exercise, sessions: templateSessions)
        }
    }

    private func startExercise() {
        // Create a quick session with just this exercise
        let session = TrainingSession(
            name: exercise.name,
            description: "Quick practice: \(exercise.name)",
            templateType: .quickSession,
            defaultRestSeconds: 30,
            isTemplate: false
        )
        session.addExercise(exercise, durationSeconds: 300, restAfterSeconds: 0)
        modelContext.insert(session)
        quickSession = session
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                CategoryIconView(category: exercise.category, size: .large)
                SkillLevelBadge(level: exercise.skillLevel)

                if exercise.isUserCreated {
                    Text("Custom")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }

                Spacer()
            }

            Text(exercise.exerciseDescription)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            MetadataItem(
                title: "Training Type",
                value: exercise.trainingType.rawValue,
                iconName: exercise.trainingType.iconName
            )

            MetadataItem(
                title: "Duration",
                value: exercise.duration.rawValue,
                iconName: "clock"
            )

            MetadataItem(
                title: "Space Required",
                value: exercise.spaceRequired.rawValue,
                iconName: "square.dashed"
            )

            MetadataItem(
                title: "Category",
                value: exercise.category.rawValue,
                iconName: exercise.category.iconName
            )
        }
    }

    // MARK: - Equipment Section

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Equipment Needed", iconName: "bag")

            FlowLayout(spacing: 8) {
                ForEach(exercise.equipment) { item in
                    EquipmentBadgeView(equipment: item, style: .large)
                }
            }
        }
    }

    // MARK: - Coaching Points Section

    private var coachingPointsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Coaching Points", iconName: "checkmark.circle")

            VStack(alignment: .leading, spacing: 10) {
                ForEach(exercise.coachingPoints, id: \.self) { point in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.body)
                        Text(point)
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    // MARK: - Common Mistakes Section

    private var commonMistakesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Common Mistakes", iconName: "xmark.circle")

            VStack(alignment: .leading, spacing: 10) {
                ForEach(exercise.commonMistakes, id: \.self) { mistake in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.body)
                        Text(mistake)
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    // MARK: - Variations Section

    private var variationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Variations & Progressions", iconName: "arrow.up.right.circle")

            VStack(alignment: .leading, spacing: 10) {
                ForEach(exercise.variations, id: \.self) { variation in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.body)
                        Text(variation)
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Tags", iconName: "tag")

            FlowLayout(spacing: 8) {
                ForEach(exercise.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    var iconName: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let iconName {
                Image(systemName: iconName)
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.headline)
        }
    }
}

struct MetadataItem: View {
    let title: String
    let value: String
    let iconName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: iconName)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Flow Layout for Tags/Badges

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

// MARK: - Add Exercise to Session Sheet

struct AddExerciseToSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let exercise: Exercise
    let sessions: [TrainingSession]

    @State private var selectedSession: TrainingSession?
    @State private var duration: Int = 300
    @State private var restAfter: Int = 30
    @State private var showingCreateSession = false

    var body: some View {
        NavigationStack {
            Form {
                if sessions.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No Sessions",
                            systemImage: "figure.run",
                            description: Text("Create a session first to add exercises")
                        )
                    }
                } else {
                    Section("Select Session") {
                        ForEach(sessions) { session in
                            Button {
                                selectedSession = session
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(session.name)
                                            .foregroundStyle(.primary)
                                        Text("\(session.exerciseCount) exercises")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if selectedSession?.id == session.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Section("Exercise Settings") {
                        Stepper("Duration: \(duration / 60) min", value: $duration, in: 60...1800, step: 60)
                        Stepper("Rest after: \(restAfter)s", value: $restAfter, in: 0...120, step: 15)
                    }
                }

                Section {
                    Button {
                        showingCreateSession = true
                    } label: {
                        Label("Create New Session", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("Add to Session")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addToSession()
                    }
                    .disabled(selectedSession == nil)
                }
            }
            .sheet(isPresented: $showingCreateSession) {
                CreateSessionView(templateType: .custom)
            }
        }
    }

    private func addToSession() {
        guard let session = selectedSession else { return }
        session.addExercise(exercise, durationSeconds: duration, restAfterSeconds: restAfter)
        session.updatedAt = Date()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: Exercise(
            name: "Cone Weave Dribbling",
            description: "Navigate through a line of cones using close ball control, alternating feet with each touch. This is a fundamental drill for developing close control and quick feet.",
            category: .dribbling,
            trainingType: .solo,
            skillLevel: .beginner,
            duration: .short,
            spaceRequired: .small,
            equipment: [.ball, .cones],
            videoURL: nil,
            coachingPoints: [
                "Keep the ball close to your feet",
                "Use both inside and outside of feet",
                "Keep your head up"
            ],
            commonMistakes: [
                "Pushing ball too far ahead",
                "Only using one foot"
            ],
            variations: [
                "Increase speed",
                "Use weak foot only"
            ],
            tags: ["ball control", "footwork", "basics"]
        ))
    }
}
