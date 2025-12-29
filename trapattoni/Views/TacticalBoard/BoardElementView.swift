import SwiftUI
import SwiftData

/// Renders individual elements on the tactical board
struct BoardElementView: View {
    let element: BoardElement
    let isSelected: Bool
    let boardSize: CGSize

    private var scaleFactor: CGFloat {
        min(boardSize.width, boardSize.height) / 400
    }

    var body: some View {
        ZStack {
            // Selection ring
            if isSelected {
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: elementSize + 12, height: elementSize + 12)
                    .shadow(color: .white.opacity(0.5), radius: 4)
            }

            // Element content
            elementContent
        }
        .rotationEffect(.degrees(element.rotation))
        .scaleEffect(element.scale)
    }

    @ViewBuilder
    private var elementContent: some View {
        switch element.elementType {
        case .player:
            playerView
        case .goalkeeper:
            goalkeeperView
        case .ball:
            ballView
        case .cone:
            coneView
        case .flag:
            flagView
        case .mannequin:
            mannequinView
        case .ladder:
            ladderView
        case .goal:
            goalView(mini: false)
        case .miniGoal:
            goalView(mini: true)
        }
    }

    private var elementSize: CGFloat {
        switch element.elementType {
        case .player, .goalkeeper: return 32 * scaleFactor
        case .ball: return 18 * scaleFactor
        case .cone: return 20 * scaleFactor
        case .flag: return 24 * scaleFactor
        case .mannequin: return 28 * scaleFactor
        case .ladder: return 50 * scaleFactor
        case .goal: return 70 * scaleFactor
        case .miniGoal: return 45 * scaleFactor
        }
    }

    // MARK: - Player Views

    private var playerView: some View {
        ZStack {
            // Shadow
            Circle()
                .fill(Color.black.opacity(0.3))
                .frame(width: elementSize, height: elementSize)
                .offset(x: 2, y: 2)

            // Body
            Circle()
                .fill(element.teamColor.color)
                .frame(width: elementSize, height: elementSize)

            // White border
            Circle()
                .stroke(Color.white, lineWidth: 2 * scaleFactor)
                .frame(width: elementSize, height: elementSize)

            // Number
            if let number = element.number {
                Text("\(number)")
                    .font(.system(size: 14 * scaleFactor, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    private var goalkeeperView: some View {
        ZStack {
            // Shadow
            Circle()
                .fill(Color.black.opacity(0.3))
                .frame(width: elementSize, height: elementSize)
                .offset(x: 2, y: 2)

            // Body with gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [element.teamColor.color, element.teamColor.secondaryColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: elementSize, height: elementSize)

            // Diamond pattern overlay for GK
            Circle()
                .stroke(Color.white, lineWidth: 3 * scaleFactor)
                .frame(width: elementSize, height: elementSize)

            // Inner ring
            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: 1 * scaleFactor)
                .frame(width: elementSize * 0.7, height: elementSize * 0.7)

            // Number or GK
            if let number = element.number {
                Text("\(number)")
                    .font(.system(size: 12 * scaleFactor, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Text("GK")
                    .font(.system(size: 10 * scaleFactor, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Ball View

    private var ballView: some View {
        ZStack {
            // Shadow
            Ellipse()
                .fill(Color.black.opacity(0.3))
                .frame(width: elementSize * 1.1, height: elementSize * 0.4)
                .offset(y: elementSize * 0.4)

            // Ball
            Circle()
                .fill(Color.white)
                .frame(width: elementSize, height: elementSize)

            // Pentagon pattern
            Circle()
                .stroke(Color.black, lineWidth: 1 * scaleFactor)
                .frame(width: elementSize, height: elementSize)

            // Inner pentagon
            PentagonShape()
                .fill(Color.black)
                .frame(width: elementSize * 0.45, height: elementSize * 0.45)
        }
    }

    // MARK: - Equipment Views

    private var coneView: some View {
        ZStack {
            // Shadow
            Ellipse()
                .fill(Color.black.opacity(0.3))
                .frame(width: elementSize * 0.8, height: elementSize * 0.3)
                .offset(y: elementSize * 0.35)

            // Cone
            Triangle()
                .fill(
                    LinearGradient(
                        colors: [.orange, .orange.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: elementSize, height: elementSize)

            // Cone stripes
            Triangle()
                .stroke(Color.white.opacity(0.5), lineWidth: 1 * scaleFactor)
                .frame(width: elementSize, height: elementSize)
        }
    }

    private var flagView: some View {
        ZStack {
            // Pole
            Rectangle()
                .fill(Color.gray)
                .frame(width: 3 * scaleFactor, height: elementSize)

            // Flag
            Path { path in
                path.move(to: CGPoint(x: 0, y: -elementSize / 2))
                path.addLine(to: CGPoint(x: elementSize * 0.6, y: -elementSize / 2 + elementSize * 0.2))
                path.addLine(to: CGPoint(x: 0, y: -elementSize / 2 + elementSize * 0.4))
                path.closeSubpath()
            }
            .fill(element.teamColor.color)
            .offset(x: 1.5 * scaleFactor)
        }
    }

    private var mannequinView: some View {
        ZStack {
            // Shadow
            Ellipse()
                .fill(Color.black.opacity(0.3))
                .frame(width: elementSize * 0.5, height: elementSize * 0.2)
                .offset(y: elementSize * 0.45)

            // Body
            Capsule()
                .fill(Color.gray.opacity(0.8))
                .frame(width: elementSize * 0.4, height: elementSize * 0.7)
                .offset(y: elementSize * 0.05)

            // Head
            Circle()
                .fill(Color.gray.opacity(0.8))
                .frame(width: elementSize * 0.35, height: elementSize * 0.35)
                .offset(y: -elementSize * 0.35)

            // Outline
            Capsule()
                .stroke(Color.gray, lineWidth: 1 * scaleFactor)
                .frame(width: elementSize * 0.4, height: elementSize * 0.7)
                .offset(y: elementSize * 0.05)
        }
    }

    private var ladderView: some View {
        ZStack {
            // Ladder shape
            VStack(spacing: 4 * scaleFactor) {
                ForEach(0..<5, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.yellow)
                        .frame(width: elementSize * 0.8, height: 3 * scaleFactor)
                }
            }
            .frame(width: elementSize, height: elementSize * 1.2)
            .overlay(
                HStack {
                    Rectangle()
                        .fill(Color.yellow)
                        .frame(width: 3 * scaleFactor)
                    Spacer()
                    Rectangle()
                        .fill(Color.yellow)
                        .frame(width: 3 * scaleFactor)
                }
            )
        }
    }

    private func goalView(mini: Bool) -> some View {
        let width = mini ? elementSize * 0.8 : elementSize
        let height = mini ? elementSize * 0.4 : elementSize * 0.5

        return ZStack {
            // Net background
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: width, height: height * 0.6)
                .offset(y: -height * 0.15)

            // Goal frame
            GoalShape()
                .stroke(Color.white, lineWidth: 4 * scaleFactor)
                .frame(width: width, height: height)

            // Net pattern
            NetPattern()
                .stroke(Color.white.opacity(0.3), lineWidth: 0.5 * scaleFactor)
                .frame(width: width * 0.9, height: height * 0.5)
                .offset(y: -height * 0.15)
        }
    }
}

// MARK: - Custom Shapes

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct PentagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        for i in 0..<5 {
            let angle = CGFloat(i) * .pi * 2 / 5 - .pi / 2
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct GoalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // U-shape for goal
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}

struct NetPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 8

        // Vertical lines
        for x in stride(from: rect.minX, through: rect.maxX, by: spacing) {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }

        // Horizontal lines
        for y in stride(from: rect.minY, through: rect.maxY, by: spacing) {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }

        return path
    }
}

// MARK: - Preview

#Preview("All Elements") {
    VStack(spacing: 20) {
        HStack(spacing: 30) {
            BoardElementView(
                element: BoardElement(elementType: .player, position: .zero, teamColor: .home, number: 10),
                isSelected: false,
                boardSize: CGSize(width: 400, height: 300)
            )

            BoardElementView(
                element: BoardElement(elementType: .goalkeeper, position: .zero, teamColor: .away, number: 1),
                isSelected: true,
                boardSize: CGSize(width: 400, height: 300)
            )

            BoardElementView(
                element: BoardElement(elementType: .ball, position: .zero),
                isSelected: false,
                boardSize: CGSize(width: 400, height: 300)
            )
        }

        HStack(spacing: 30) {
            BoardElementView(
                element: BoardElement(elementType: .cone, position: .zero),
                isSelected: false,
                boardSize: CGSize(width: 400, height: 300)
            )

            BoardElementView(
                element: BoardElement(elementType: .mannequin, position: .zero),
                isSelected: false,
                boardSize: CGSize(width: 400, height: 300)
            )

            BoardElementView(
                element: BoardElement(elementType: .flag, position: .zero, teamColor: .home),
                isSelected: false,
                boardSize: CGSize(width: 400, height: 300)
            )
        }
    }
    .padding()
    .background(Color.green.opacity(0.5))
}
