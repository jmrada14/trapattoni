import SwiftUI
import SwiftData

/// Interactive tactical board for coaches to create and edit tactics
struct CoachTacticalBoardView: View {
    @Bindable var tacticSheet: TacticSheet
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTool: BoardTool = .select
    @State private var selectedTeamColor: TeamColor = .home
    @State private var selectedStrokeColor: StrokeColor = .white
    @State private var selectedElement: BoardElement?
    @State private var selectedDrawing: DrawingPath?
    @State private var currentDrawingPoints: [CGPoint] = []
    @State private var isDrawing: Bool = false
    @State private var boardSize: CGSize = .zero
    @State private var showElementOptions: Bool = false
    @State private var playerNumber: Int = 1
    @State private var draggedElement: BoardElement?

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top toolbar
                toolbarView

                // Main board area - takes all available space
                boardArea
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bottom toolbar
                bottomToolbarView
            }
        }
        .sheet(isPresented: $showElementOptions) {
            if let element = selectedElement {
                ElementOptionsSheet(element: element, onDelete: deleteSelectedElement)
            }
        }
    }

    // MARK: - Board Area

    private func calculateBoardSize(availableSize: CGSize, aspectRatio: CGFloat) -> CGSize {
        // Guard against zero or too-small sizes (happens on initial render)
        guard availableSize.width > 32, availableSize.height > 32 else {
            return CGSize(width: 100, height: 100 / aspectRatio)
        }

        let widthBasedHeight = availableSize.width / aspectRatio
        if widthBasedHeight <= availableSize.height {
            let boardWidth = availableSize.width - 16
            return CGSize(width: boardWidth, height: boardWidth / aspectRatio)
        } else {
            let boardHeight = availableSize.height - 16
            return CGSize(width: boardHeight * aspectRatio, height: boardHeight)
        }
    }

    private var boardArea: some View {
        GeometryReader { geo in
            // Skip rendering if geometry isn't ready yet
            if geo.size.width > 0 && geo.size.height > 0 {
                let calculatedSize = calculateBoardSize(
                    availableSize: geo.size,
                    aspectRatio: tacticSheet.fieldType.aspectRatio
                )
                let boardWidth = calculatedSize.width
                let boardHeight = calculatedSize.height

                ZStack {
                // Field background
                CoachFieldCanvas(fieldType: tacticSheet.fieldType)
                    .frame(width: boardWidth, height: boardHeight)

                // Elements layer
                ForEach(tacticSheet.elements.sorted(by: { $0.zIndex < $1.zIndex })) { element in
                    BoardElementView(
                        element: element,
                        isSelected: selectedElement?.id == element.id,
                        boardSize: CGSize(width: boardWidth, height: boardHeight)
                    )
                    .position(
                        x: element.positionX * boardWidth,
                        y: element.positionY * boardHeight
                    )
                    .gesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { value in
                                if selectedTool == .select || selectedTool == .player || selectedTool == .goalkeeper || selectedTool == .ball || selectedTool == .equipment {
                                    let newX = value.location.x / boardWidth
                                    let newY = value.location.y / boardHeight
                                    element.positionX = min(max(newX, 0.03), 0.97)
                                    element.positionY = min(max(newY, 0.03), 0.97)
                                    selectedElement = element
                                    tacticSheet.updatedAt = Date()
                                }
                            }
                    )
                    .onTapGesture {
                        if selectedTool == .select {
                            selectedElement = element
                            showElementOptions = true
                        } else if selectedTool == .eraser {
                            deleteElement(element)
                        }
                    }
                }

                // Drawings layer
                ForEach(tacticSheet.drawings.sorted(by: { $0.zIndex < $1.zIndex })) { drawing in
                    DrawingPathView(
                        drawing: drawing,
                        boardSize: CGSize(width: boardWidth, height: boardHeight),
                        isEraserActive: selectedTool == .eraser
                    )
                    .onTapGesture {
                        if selectedTool == .eraser {
                            deleteDrawing(drawing)
                        }
                    }
                }

                // Current drawing preview
                if isDrawing && !currentDrawingPoints.isEmpty {
                    currentDrawingPreview(boardSize: CGSize(width: boardWidth, height: boardHeight))
                }

                // Tap/Draw gesture overlay (only active for certain tools)
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                handleDragChanged(value, boardSize: CGSize(width: boardWidth, height: boardHeight))
                            }
                            .onEnded { value in
                                handleDragEnded(value, boardSize: CGSize(width: boardWidth, height: boardHeight))
                            }
                    )
                    .allowsHitTesting(shouldCaptureGestures)
            }
            .frame(width: boardWidth, height: boardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                boardSize = CGSize(width: boardWidth, height: boardHeight)
            }
            .onChange(of: geo.size) { _, _ in
                boardSize = CGSize(width: boardWidth, height: boardHeight)
            }
            }
        }
        .padding(8)
    }

    private var shouldCaptureGestures: Bool {
        switch selectedTool {
        case .player, .goalkeeper, .ball, .equipment:
            return true // For tapping to place
        case .arrow, .line, .curvedArrow, .zone, .freehand:
            return true // For drawing
        case .select, .eraser:
            return false // Let element gestures through
        }
    }

    // MARK: - Top Toolbar

    private var toolbarView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(BoardTool.allCases) { tool in
                    ToolButton(
                        tool: tool,
                        isSelected: selectedTool == tool,
                        action: { selectedTool = tool }
                    )
                }

                Divider()
                    .frame(height: 30)
                    .padding(.horizontal, 4)

                // Team color picker
                if selectedTool == .player || selectedTool == .goalkeeper {
                    teamColorPicker
                }

                // Stroke color picker for drawing tools
                if selectedTool.isDrawingTool {
                    strokeColorPicker
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(Color.systemBackground.opacity(0.95))
    }

    private var teamColorPicker: some View {
        HStack(spacing: 6) {
            ForEach(TeamColor.allCases, id: \.self) { color in
                Circle()
                    .fill(color.color)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .stroke(selectedTeamColor == color ? Color.white : Color.clear, lineWidth: 3)
                    )
                    .shadow(color: selectedTeamColor == color ? color.color.opacity(0.5) : .clear, radius: 4)
                    .onTapGesture {
                        selectedTeamColor = color
                    }
            }
        }
    }

    private var strokeColorPicker: some View {
        HStack(spacing: 4) {
            ForEach(StrokeColor.allCases, id: \.self) { color in
                Circle()
                    .fill(color.color)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(selectedStrokeColor == color ? Color.primary : Color.clear, lineWidth: 2)
                    )
                    .onTapGesture {
                        selectedStrokeColor = color
                    }
            }
        }
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbarView: some View {
        HStack {
            Button(action: undoLastAction) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.title3)
            }
            .disabled(tacticSheet.elements.isEmpty && tacticSheet.drawings.isEmpty)

            Spacer()

            Menu {
                ForEach(FieldType.allCases, id: \.self) { type in
                    Button(type.rawValue) {
                        tacticSheet.fieldType = type
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "sportscourt")
                    Text(tacticSheet.fieldType.rawValue)
                        .font(.subheadline)
                }
            }

            Spacer()

            Button(action: clearBoard) {
                Image(systemName: "trash")
                    .font(.title3)
            }
            .foregroundStyle(.red)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.systemBackground.opacity(0.95))
    }

    // MARK: - Current Drawing Preview

    private func currentDrawingPreview(boardSize: CGSize) -> some View {
        Canvas { context, size in
            guard currentDrawingPoints.count >= 2 else { return }

            var path = Path()
            path.move(to: currentDrawingPoints[0])

            for point in currentDrawingPoints.dropFirst() {
                path.addLine(to: point)
            }

            context.stroke(
                path,
                with: .color(selectedStrokeColor.color),
                lineWidth: 3
            )

            // Draw arrow head for arrow tools
            if (selectedTool == .arrow || selectedTool == .curvedArrow),
               let lastPoint = currentDrawingPoints.last,
               currentDrawingPoints.count >= 2 {
                let secondLast = currentDrawingPoints[currentDrawingPoints.count - 2]
                drawArrowHead(context: context, from: secondLast, to: lastPoint, color: selectedStrokeColor.color)
            }
        }
        .allowsHitTesting(false)
    }

    private func drawArrowHead(context: GraphicsContext, from: CGPoint, to: CGPoint, color: Color) {
        let angle = atan2(to.y - from.y, to.x - from.x)
        let arrowLength: CGFloat = 15
        let arrowAngle: CGFloat = .pi / 6

        var arrowPath = Path()
        arrowPath.move(to: to)
        arrowPath.addLine(to: CGPoint(
            x: to.x - arrowLength * cos(angle - arrowAngle),
            y: to.y - arrowLength * sin(angle - arrowAngle)
        ))
        arrowPath.move(to: to)
        arrowPath.addLine(to: CGPoint(
            x: to.x - arrowLength * cos(angle + arrowAngle),
            y: to.y - arrowLength * sin(angle + arrowAngle)
        ))

        context.stroke(arrowPath, with: .color(color), lineWidth: 3)
    }

    // MARK: - Gesture Handlers

    private func handleDragChanged(_ value: DragGesture.Value, boardSize: CGSize) {
        let location = value.location

        switch selectedTool {
        case .arrow, .line, .curvedArrow, .zone, .freehand:
            if !isDrawing {
                isDrawing = true
                currentDrawingPoints = [location]
            } else {
                // Only add point if it's far enough from the last one (for smoother lines)
                if let lastPoint = currentDrawingPoints.last {
                    let distance = sqrt(pow(location.x - lastPoint.x, 2) + pow(location.y - lastPoint.y, 2))
                    if distance > 5 {
                        currentDrawingPoints.append(location)
                    }
                }
            }
        default:
            break
        }
    }

    private func handleDragEnded(_ value: DragGesture.Value, boardSize: CGSize) {
        let location = value.location
        let normalizedX = location.x / boardSize.width
        let normalizedY = location.y / boardSize.height

        // Ensure within bounds
        guard normalizedX >= 0, normalizedX <= 1, normalizedY >= 0, normalizedY <= 1 else {
            resetDrawingState()
            return
        }

        switch selectedTool {
        case .player:
            addPlayer(at: CGPoint(x: normalizedX, y: normalizedY), isGoalkeeper: false)
        case .goalkeeper:
            addPlayer(at: CGPoint(x: normalizedX, y: normalizedY), isGoalkeeper: true)
        case .ball:
            addBall(at: CGPoint(x: normalizedX, y: normalizedY))
        case .equipment:
            addEquipment(at: CGPoint(x: normalizedX, y: normalizedY))
        case .arrow, .line, .curvedArrow, .zone, .freehand:
            finishDrawing(boardSize: boardSize)
        default:
            break
        }

        if !selectedTool.isDrawingTool {
            resetDrawingState()
        }
    }

    // MARK: - Actions

    private func addPlayer(at position: CGPoint, isGoalkeeper: Bool) {
        let element = BoardElement(
            elementType: isGoalkeeper ? .goalkeeper : .player,
            position: position,
            teamColor: selectedTeamColor,
            number: playerNumber,
            zIndex: tacticSheet.elements.count
        )
        tacticSheet.elements.append(element)
        playerNumber += 1
        if playerNumber > 11 { playerNumber = 1 }
        tacticSheet.updatedAt = Date()
    }

    private func addBall(at position: CGPoint) {
        let element = BoardElement(
            elementType: .ball,
            position: position,
            teamColor: .neutral,
            zIndex: tacticSheet.elements.count + 100
        )
        tacticSheet.elements.append(element)
        tacticSheet.updatedAt = Date()
    }

    private func addEquipment(at position: CGPoint) {
        let element = BoardElement(
            elementType: .cone,
            position: position,
            teamColor: .neutral,
            zIndex: tacticSheet.elements.count
        )
        tacticSheet.elements.append(element)
        tacticSheet.updatedAt = Date()
    }

    private func finishDrawing(boardSize: CGSize) {
        guard currentDrawingPoints.count >= 2 else {
            resetDrawingState()
            return
        }

        let pathType: PathType
        switch selectedTool {
        case .arrow: pathType = .arrow
        case .line: pathType = .line
        case .curvedArrow: pathType = .curvedArrow
        case .zone: pathType = .zone
        case .freehand: pathType = .freehand
        default: pathType = .line
        }

        let normalizedPoints = currentDrawingPoints.map { point in
            PathPoint(x: point.x / boardSize.width, y: point.y / boardSize.height)
        }

        let drawing = DrawingPath(
            pathType: pathType,
            points: normalizedPoints,
            strokeColor: selectedStrokeColor,
            strokeWidth: 3,
            isDashed: pathType == .dottedRun,
            hasArrowHead: pathType == .arrow || pathType == .curvedArrow || pathType == .passLine,
            fillOpacity: pathType == .zone ? 0.3 : 0,
            zIndex: tacticSheet.drawings.count
        )

        tacticSheet.drawings.append(drawing)
        tacticSheet.updatedAt = Date()
        resetDrawingState()
    }

    private func resetDrawingState() {
        isDrawing = false
        currentDrawingPoints = []
    }

    private func deleteElement(_ element: BoardElement) {
        tacticSheet.elements.removeAll { $0.id == element.id }
        modelContext.delete(element)
        tacticSheet.updatedAt = Date()
        recalculatePlayerNumber()
    }

    private func recalculatePlayerNumber() {
        // Get all remaining players and goalkeepers
        let playerElements = tacticSheet.elements.filter {
            $0.elementType == .player || $0.elementType == .goalkeeper
        }

        if playerElements.isEmpty {
            // Reset to 1 when no players remain
            playerNumber = 1
        } else {
            // Set to next available number after highest existing
            let maxNumber = playerElements.compactMap { $0.number }.max() ?? 0
            playerNumber = (maxNumber % 11) + 1
        }
    }

    private func deleteSelectedElement() {
        if let element = selectedElement {
            deleteElement(element)
            selectedElement = nil
            showElementOptions = false
        }
    }

    private func deleteDrawing(_ drawing: DrawingPath) {
        tacticSheet.drawings.removeAll { $0.id == drawing.id }
        modelContext.delete(drawing)
        tacticSheet.updatedAt = Date()
    }

    private func undoLastAction() {
        if let lastDrawing = tacticSheet.drawings.last {
            deleteDrawing(lastDrawing)
        } else if let lastElement = tacticSheet.elements.last {
            deleteElement(lastElement)
        }
        recalculatePlayerNumber()
    }

    private func clearBoard() {
        for element in tacticSheet.elements {
            modelContext.delete(element)
        }
        for drawing in tacticSheet.drawings {
            modelContext.delete(drawing)
        }
        tacticSheet.elements.removeAll()
        tacticSheet.drawings.removeAll()
        playerNumber = 1
        tacticSheet.updatedAt = Date()
    }
}

// MARK: - Supporting Views

struct ToolButton: View {
    let tool: BoardTool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: tool.icon)
                    .font(.system(size: 16))
                Text(tool.rawValue)
                    .font(.system(size: 9))
                    .lineLimit(1)
            }
            .frame(width: 48, height: 40)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .primary : .secondary)
    }
}

struct BoardSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TacticSheet.self, configurations: config)
    let sheet = TacticSheet(name: "Test Tactic")
    container.mainContext.insert(sheet)

    return CoachTacticalBoardView(tacticSheet: sheet)
        .modelContainer(container)
}
