import SwiftUI
import SwiftData

/// Main view for managing and browsing tactics
struct TacticsLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TacticSheet.updatedAt, order: .reverse) private var tactics: [TacticSheet]

    @State private var searchText = ""
    @State private var showingNewTacticSheet = false
    @State private var selectedTactic: TacticSheet?
    @State private var showingDeleteAlert = false
    @State private var tacticToDelete: TacticSheet?

    private var filteredTactics: [TacticSheet] {
        if searchText.isEmpty {
            return tactics
        }
        return tactics.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.sheetDescription.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if tactics.isEmpty {
                    emptyStateView
                } else {
                    tacticsList
                }
            }
            .navigationTitle("tactics.title".localized)
            .searchable(text: $searchText, prompt: "tactics.search".localized)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewTacticSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewTacticSheet) {
                NewTacticSheet { newTactic in
                    modelContext.insert(newTactic)
                    selectedTactic = newTactic
                }
            }
            .navigationDestination(item: $selectedTactic) { tactic in
                TacticEditorView(tacticSheet: tactic)
            }
            .alert("tactics.delete".localized, isPresented: $showingDeleteAlert) {
                Button("common.cancel".localized, role: .cancel) {}
                Button("common.delete".localized, role: .destructive) {
                    if let tactic = tacticToDelete {
                        deleteTactic(tactic)
                    }
                }
            } message: {
                Text("tactics.deleteConfirm".localized)
            }
            .observeLanguageChanges()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("tactics.noTactics".localized, systemImage: "sportscourt")
        } description: {
            Text("tactics.createFirst".localized)
        } actions: {
            Button {
                showingNewTacticSheet = true
            } label: {
                Text("tactics.create".localized)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Tactics List

    private var tacticsList: some View {
        List {
            ForEach(filteredTactics) { tactic in
                TacticCardView(tactic: tactic)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTactic = tactic
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            tacticToDelete = tactic
                            showingDeleteAlert = true
                        } label: {
                            Label("common.delete".localized, systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            duplicateTactic(tactic)
                        } label: {
                            Label("sessions.duplicate".localized, systemImage: "doc.on.doc")
                        }
                        .tint(.blue)
                    }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
    }

    // MARK: - Actions

    private func deleteTactic(_ tactic: TacticSheet) {
        modelContext.delete(tactic)
        tacticToDelete = nil
    }

    private func duplicateTactic(_ tactic: TacticSheet) {
        let newTactic = TacticSheet(
            name: "\(tactic.name) (Copy)",
            sheetDescription: tactic.sheetDescription,
            fieldType: tactic.fieldType
        )

        // Copy elements
        for element in tactic.elements {
            let newElement = BoardElement(
                elementType: element.elementType,
                position: CGPoint(x: element.positionX, y: element.positionY),
                rotation: element.rotation,
                scale: element.scale,
                label: element.label,
                teamColor: element.teamColor,
                number: element.number,
                zIndex: element.zIndex
            )
            newTactic.elements.append(newElement)
        }

        // Copy drawings
        for drawing in tactic.drawings {
            let newDrawing = DrawingPath(
                pathType: drawing.pathType,
                points: drawing.points,
                strokeColor: drawing.strokeColor,
                strokeWidth: drawing.strokeWidth,
                isDashed: drawing.isDashed,
                hasArrowHead: drawing.hasArrowHead,
                fillOpacity: drawing.fillOpacity,
                zIndex: drawing.zIndex
            )
            newTactic.drawings.append(newDrawing)
        }

        modelContext.insert(newTactic)
    }
}

// MARK: - Tactic Card View

struct TacticCardView: View {
    let tactic: TacticSheet

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(tactic.name)
                    .font(.body)
                    .fontWeight(.medium)

                if !tactic.sheetDescription.isEmpty {
                    Text(tactic.sheetDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    Text(tactic.fieldType.localizedName)
                    Text("•")
                    Text(tactic.updatedAt.formatted(date: .abbreviated, time: .omitted))
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Tactic Preview Canvas

struct TacticPreviewCanvas: View {
    let tactic: TacticSheet

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Field background
                CoachFieldCanvas(fieldType: tactic.fieldType)

                // Elements (simplified)
                ForEach(tactic.elements) { element in
                    Circle()
                        .fill(element.teamColor.color)
                        .frame(width: 12, height: 12)
                        .position(
                            x: element.positionX * geometry.size.width,
                            y: element.positionY * geometry.size.height
                        )
                }

                // Drawings (simplified)
                Canvas { context, size in
                    for drawing in tactic.drawings {
                        guard drawing.points.count >= 2 else { continue }

                        var path = Path()
                        let firstPoint = drawing.points[0]
                        path.move(to: CGPoint(x: firstPoint.x * size.width, y: firstPoint.y * size.height))

                        for point in drawing.points.dropFirst() {
                            path.addLine(to: CGPoint(x: point.x * size.width, y: point.y * size.height))
                        }

                        context.stroke(
                            path,
                            with: .color(drawing.strokeColor.color),
                            lineWidth: 2
                        )
                    }
                }
            }
        }
    }
}

// MARK: - New Tactic Sheet

struct NewTacticSheet: View {
    let onCreate: (TacticSheet) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var fieldType: FieldType = .fullField

    var body: some View {
        NavigationStack {
            Form {
                Section("profile.name".localized) {
                    TextField("tactics.name".localized, text: $name)
                }

                Section("exercise.description".localized) {
                    TextField("tactics.description".localized, text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("tactics.fieldType".localized) {
                    Picker("tactics.fieldType".localized, selection: $fieldType) {
                        ForEach(FieldType.allCases, id: \.self) { type in
                            Text(type.localizedName).tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                }

                // Preview
                Section("tactics.preview".localized) {
                    CoachFieldCanvas(fieldType: fieldType)
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .navigationTitle("tactics.new".localized)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("tactics.create".localized) {
                        let tactic = TacticSheet(
                            name: name.isEmpty ? "tactics.new".localized : name,
                            sheetDescription: description,
                            fieldType: fieldType
                        )
                        onCreate(tactic)
                        dismiss()
                    }
                }
            }
            .observeLanguageChanges()
        }
    }
}

// MARK: - Tactic Editor View

struct TacticEditorView: View {
    @Bindable var tacticSheet: TacticSheet
    @Environment(\.dismiss) private var dismiss

    @State private var showingRenameSheet = false

    var body: some View {
        CoachTacticalBoardView(tacticSheet: tacticSheet)
            .navigationTitle(tacticSheet.name)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingRenameSheet = true
                        } label: {
                            Label("tactics.rename".localized, systemImage: "pencil")
                        }

                        Button {
                            shareTactic()
                        } label: {
                            Label("tactics.share".localized, systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingRenameSheet) {
                RenameTacticSheet(tactic: tacticSheet)
            }
    }

    private func shareTactic() {
        // Placeholder for share functionality
    }
}

// MARK: - Rename Tactic Sheet

struct RenameTacticSheet: View {
    @Bindable var tactic: TacticSheet
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var description: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("profile.name".localized) {
                    TextField("tactics.name".localized, text: $name)
                }

                Section("exercise.description".localized) {
                    TextField("tactics.description".localized, text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("tactics.fieldType".localized) {
                    Picker("tactics.fieldType".localized, selection: $tactic.fieldType) {
                        ForEach(FieldType.allCases, id: \.self) { type in
                            Text(type.localizedName).tag(type)
                        }
                    }
                }
            }
            .navigationTitle("tactics.edit".localized)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized) {
                        tactic.name = name
                        tactic.sheetDescription = description
                        tactic.updatedAt = Date()
                        dismiss()
                    }
                }
            }
            .onAppear {
                name = tactic.name
                description = tactic.sheetDescription
            }
            .observeLanguageChanges()
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TacticSheet.self, configurations: config)

    // Add sample tactics
    let tactic1 = TacticSheet(name: "4-4-2 Formation", sheetDescription: "Basic defensive formation", fieldType: .fullField)
    let tactic2 = TacticSheet(name: "Counter Attack", sheetDescription: "Quick transition play", fieldType: .halfField)

    container.mainContext.insert(tactic1)
    container.mainContext.insert(tactic2)

    return TacticsLibraryView()
        .modelContainer(container)
}
