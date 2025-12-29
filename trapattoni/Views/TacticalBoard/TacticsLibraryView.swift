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
            .navigationTitle("Tactical Board")
            .searchable(text: $searchText, prompt: "Search tactics")
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
            .alert("Delete Tactic?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let tactic = tacticToDelete {
                        deleteTactic(tactic)
                    }
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Tactics", systemImage: "sportscourt")
        } description: {
            Text("Create your first tactic to explain formations, plays, and strategies to your team.")
        } actions: {
            Button {
                showingNewTacticSheet = true
            } label: {
                Text("Create Tactic")
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
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            duplicateTactic(tactic)
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
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
                    Text(tactic.fieldType.rawValue)
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
                Section("Name") {
                    TextField("Tactic name", text: $name)
                }

                Section("Description") {
                    TextField("Optional description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Field Type") {
                    Picker("Field", selection: $fieldType) {
                        ForEach(FieldType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                }

                // Preview
                Section("Preview") {
                    CoachFieldCanvas(fieldType: fieldType)
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .navigationTitle("New Tactic")
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
                    Button("Create") {
                        let tactic = TacticSheet(
                            name: name.isEmpty ? "New Tactic" : name,
                            sheetDescription: description,
                            fieldType: fieldType
                        )
                        onCreate(tactic)
                        dismiss()
                    }
                }
            }
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
                            Label("Rename", systemImage: "pencil")
                        }

                        Button {
                            shareTactic()
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
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
                Section("Name") {
                    TextField("Tactic name", text: $name)
                }

                Section("Description") {
                    TextField("Optional description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Field Type") {
                    Picker("Field", selection: $tactic.fieldType) {
                        ForEach(FieldType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
            }
            .navigationTitle("Edit Tactic")
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
                    Button("Save") {
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
