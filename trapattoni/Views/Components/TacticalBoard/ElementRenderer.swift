import SwiftUI

/// Draws individual elements on the tactical board
struct ElementRenderer {

    // MARK: - Element Sizes

    private static let playerRadius: CGFloat = 12
    private static let ballRadius: CGFloat = 7
    private static let coneSize: CGFloat = 10
    private static let equipmentSize: CGFloat = 18

    // MARK: - Player Number Tracking

    private static var playerNumberCounter: [PlayerRole: Int] = [:]

    static func resetPlayerNumbers() {
        playerNumberCounter = [:]
    }

    // MARK: - Main Drawing

    /// Draw an element at its current position
    static func drawElement(
        _ element: FieldElement,
        at position: FieldPosition,
        direction: Angle,
        in context: GraphicsContext,
        size: CGSize,
        scale: CGFloat = 1.0,
        playerNumber: Int? = nil
    ) {
        let point = position.toPoint(in: size)
        let elementScale = element.scale * scale

        switch element.type {
        case .player(let role):
            drawPlayer(context: context, at: point, role: role, scale: elementScale, number: playerNumber)
        case .ball:
            drawBall(context: context, at: point, scale: elementScale)
        case .cone:
            drawCone(context: context, at: point, scale: elementScale)
        case .goal(let goalSize):
            drawGoal(context: context, at: point, goalSize: goalSize, scale: elementScale)
        case .ladder:
            drawLadder(context: context, at: point, rotation: element.rotation, scale: elementScale)
        case .hurdle:
            drawHurdle(context: context, at: point, scale: elementScale)
        case .mannequin:
            drawMannequin(context: context, at: point, scale: elementScale)
        case .pole:
            drawPole(context: context, at: point, scale: elementScale)
        case .rebounder:
            drawRebounder(context: context, at: point, rotation: element.rotation, scale: elementScale)
        case .wall:
            drawWall(context: context, at: point, scale: elementScale)
        }
    }

    /// Draw movement trail for an element
    static func drawMovementTrail(
        from startPosition: FieldPosition,
        to endPosition: FieldPosition,
        progress: CGFloat,
        in context: GraphicsContext,
        size: CGSize,
        color: Color,
        isDashed: Bool = false
    ) {
        let start = startPosition.toPoint(in: size)
        let current = endPosition.interpolated(to: startPosition, progress: 1 - progress).toPoint(in: size)

        var path = Path()
        path.move(to: start)
        path.addLine(to: current)

        let style = isDashed
            ? StrokeStyle(lineWidth: 2, dash: [4, 4])
            : StrokeStyle(lineWidth: 2)

        context.stroke(path, with: .color(color.opacity(0.4)), style: style)
    }

    // MARK: - Player

    private static func drawPlayer(
        context: GraphicsContext,
        at point: CGPoint,
        role: PlayerRole,
        scale: CGFloat,
        number: Int? = nil
    ) {
        let radius = playerRadius * scale

        // Outer glow/shadow for depth
        let glowPath = Path(ellipseIn: CGRect(
            x: point.x - radius - 2,
            y: point.y - radius - 1,
            width: (radius + 2) * 2,
            height: (radius + 2) * 2
        ))
        context.fill(glowPath, with: .color(.black.opacity(0.3)))

        // Player body (filled circle with gradient effect)
        let bodyRect = CGRect(
            x: point.x - radius,
            y: point.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        let bodyPath = Path(ellipseIn: bodyRect)

        // Fill with role color
        context.fill(bodyPath, with: .color(role.color))

        // Add highlight for 3D effect
        let highlightRect = CGRect(
            x: point.x - radius * 0.5,
            y: point.y - radius * 0.7,
            width: radius * 0.8,
            height: radius * 0.5
        )
        let highlightPath = Path(ellipseIn: highlightRect)
        context.fill(highlightPath, with: .color(.white.opacity(0.3)))

        // White outline
        context.stroke(bodyPath, with: .color(.white), lineWidth: 2 * scale)

        // Draw player number if provided
        if let num = number {
            let text = Text("\(num)")
                .font(.system(size: 9 * scale, weight: .bold))
                .foregroundColor(.white)
            context.draw(text, at: point)
        }
    }

    // MARK: - Ball

    private static func drawBall(context: GraphicsContext, at point: CGPoint, scale: CGFloat) {
        let radius = ballRadius * scale

        // Shadow
        let shadowPath = Path(ellipseIn: CGRect(
            x: point.x - radius + 1,
            y: point.y - radius + 2,
            width: radius * 2,
            height: radius * 2
        ))
        context.fill(shadowPath, with: .color(.black.opacity(0.3)))

        // White ball
        let ballPath = Path(ellipseIn: CGRect(
            x: point.x - radius,
            y: point.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        context.fill(ballPath, with: .color(.white))

        // Highlight for 3D effect
        let highlightPath = Path(ellipseIn: CGRect(
            x: point.x - radius * 0.4,
            y: point.y - radius * 0.6,
            width: radius * 0.6,
            height: radius * 0.4
        ))
        context.fill(highlightPath, with: .color(.white.opacity(0.8)))

        // Black outline
        context.stroke(ballPath, with: .color(.black), lineWidth: 1.5 * scale)

        // Pentagon pattern (classic soccer ball look)
        let pentagonRadius = radius * 0.35
        var pentagonPath = Path()
        for i in 0..<5 {
            let angle = CGFloat(i) * .pi * 2 / 5 - .pi / 2
            let x = point.x + cos(angle) * pentagonRadius
            let y = point.y + sin(angle) * pentagonRadius
            if i == 0 {
                pentagonPath.move(to: CGPoint(x: x, y: y))
            } else {
                pentagonPath.addLine(to: CGPoint(x: x, y: y))
            }
        }
        pentagonPath.closeSubpath()
        context.fill(pentagonPath, with: .color(.black))
    }

    // MARK: - Cone

    private static func drawCone(context: GraphicsContext, at point: CGPoint, scale: CGFloat) {
        let size = coneSize * scale

        // Shadow
        var shadowPath = Path()
        shadowPath.move(to: CGPoint(x: point.x + 2, y: point.y - size / 2 + 2))
        shadowPath.addLine(to: CGPoint(x: point.x - size / 2 + 2, y: point.y + size / 2 + 2))
        shadowPath.addLine(to: CGPoint(x: point.x + size / 2 + 2, y: point.y + size / 2 + 2))
        shadowPath.closeSubpath()
        context.fill(shadowPath, with: .color(.black.opacity(0.2)))

        // Orange cone (triangle)
        var conePath = Path()
        conePath.move(to: CGPoint(x: point.x, y: point.y - size / 2))
        conePath.addLine(to: CGPoint(x: point.x - size / 2, y: point.y + size / 2))
        conePath.addLine(to: CGPoint(x: point.x + size / 2, y: point.y + size / 2))
        conePath.closeSubpath()

        context.fill(conePath, with: .color(.orange))

        // Highlight stripe
        var stripePath = Path()
        stripePath.move(to: CGPoint(x: point.x - size * 0.15, y: point.y))
        stripePath.addLine(to: CGPoint(x: point.x - size * 0.25, y: point.y + size * 0.25))
        stripePath.addLine(to: CGPoint(x: point.x + size * 0.05, y: point.y + size * 0.25))
        stripePath.addLine(to: CGPoint(x: point.x + size * 0.15, y: point.y))
        stripePath.closeSubpath()
        context.fill(stripePath, with: .color(.white))

        // Outline
        context.stroke(conePath, with: .color(.orange.opacity(0.8)), lineWidth: 1 * scale)
    }

    // MARK: - Goal

    private static func drawGoal(
        context: GraphicsContext,
        at point: CGPoint,
        goalSize: GoalSize,
        scale: CGFloat
    ) {
        let width: CGFloat = (goalSize == .full ? 50 : 30) * scale
        let height: CGFloat = (goalSize == .full ? 18 : 10) * scale
        let postWidth: CGFloat = 3 * scale

        // Goal frame
        let goalRect = CGRect(
            x: point.x - width / 2,
            y: point.y - height / 2,
            width: width,
            height: height
        )

        // Net background with gradient effect
        context.fill(Path(goalRect), with: .color(.white.opacity(0.15)))

        // Net pattern (vertical lines)
        let netLineCount = Int(width / 6)
        for i in 1..<netLineCount {
            var netLine = Path()
            let x = goalRect.minX + CGFloat(i) * (width / CGFloat(netLineCount))
            netLine.move(to: CGPoint(x: x, y: goalRect.minY))
            netLine.addLine(to: CGPoint(x: x, y: goalRect.maxY))
            context.stroke(netLine, with: .color(.white.opacity(0.2)), lineWidth: 0.5 * scale)
        }

        // Net pattern (horizontal lines)
        let horizontalCount = Int(height / 4)
        for i in 1..<horizontalCount {
            var netLine = Path()
            let y = goalRect.minY + CGFloat(i) * (height / CGFloat(horizontalCount))
            netLine.move(to: CGPoint(x: goalRect.minX, y: y))
            netLine.addLine(to: CGPoint(x: goalRect.maxX, y: y))
            context.stroke(netLine, with: .color(.white.opacity(0.2)), lineWidth: 0.5 * scale)
        }

        // Posts shadow
        var shadowPath = Path()
        shadowPath.move(to: CGPoint(x: goalRect.minX + 2, y: goalRect.maxY + 2))
        shadowPath.addLine(to: CGPoint(x: goalRect.minX + 2, y: goalRect.minY + 2))
        shadowPath.addLine(to: CGPoint(x: goalRect.maxX + 2, y: goalRect.minY + 2))
        shadowPath.addLine(to: CGPoint(x: goalRect.maxX + 2, y: goalRect.maxY + 2))
        context.stroke(shadowPath, with: .color(.black.opacity(0.3)), lineWidth: postWidth)

        // Posts (U-shape)
        var goalPath = Path()
        goalPath.move(to: CGPoint(x: goalRect.minX, y: goalRect.maxY))
        goalPath.addLine(to: CGPoint(x: goalRect.minX, y: goalRect.minY))
        goalPath.addLine(to: CGPoint(x: goalRect.maxX, y: goalRect.minY))
        goalPath.addLine(to: CGPoint(x: goalRect.maxX, y: goalRect.maxY))

        context.stroke(goalPath, with: .color(.white), lineWidth: postWidth)
    }

    // MARK: - Ladder

    private static func drawLadder(
        context: GraphicsContext,
        at point: CGPoint,
        rotation: Angle,
        scale: CGFloat
    ) {
        let width: CGFloat = 22 * scale
        let height: CGFloat = 55 * scale
        let rungCount = 6
        let rungSpacing = height / CGFloat(rungCount + 1)

        // Shadow
        var shadowPath = Path()
        shadowPath.addRect(CGRect(x: -width / 2 + 2, y: -height / 2 + 2, width: width, height: height))
        var shadowTransform = CGAffineTransform(translationX: point.x, y: point.y)
        shadowTransform = shadowTransform.rotated(by: rotation.radians)
        context.fill(shadowPath.applying(shadowTransform), with: .color(.black.opacity(0.2)))

        // Background fill for visibility
        var bgPath = Path()
        bgPath.addRect(CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
        var bgTransform = CGAffineTransform(translationX: point.x, y: point.y)
        bgTransform = bgTransform.rotated(by: rotation.radians)
        context.fill(bgPath.applying(bgTransform), with: .color(.yellow.opacity(0.15)))

        var ladderPath = Path()

        // Left rail
        ladderPath.move(to: CGPoint(x: -width / 2, y: -height / 2))
        ladderPath.addLine(to: CGPoint(x: -width / 2, y: height / 2))

        // Right rail
        ladderPath.move(to: CGPoint(x: width / 2, y: -height / 2))
        ladderPath.addLine(to: CGPoint(x: width / 2, y: height / 2))

        // Rungs
        for i in 1...rungCount {
            let y = -height / 2 + CGFloat(i) * rungSpacing
            ladderPath.move(to: CGPoint(x: -width / 2, y: y))
            ladderPath.addLine(to: CGPoint(x: width / 2, y: y))
        }

        // Apply rotation and translation
        var transform = CGAffineTransform(translationX: point.x, y: point.y)
        transform = transform.rotated(by: rotation.radians)

        context.stroke(
            ladderPath.applying(transform),
            with: .color(.yellow),
            lineWidth: 2.5 * scale
        )
    }

    // MARK: - Hurdle

    private static func drawHurdle(context: GraphicsContext, at point: CGPoint, scale: CGFloat) {
        let width: CGFloat = 28 * scale
        let height: CGFloat = 10 * scale
        let barHeight: CGFloat = 3 * scale
        let legWidth: CGFloat = 2.5 * scale

        // Shadow
        let shadowRect = CGRect(
            x: point.x - width / 2 + 2,
            y: point.y - height / 2 + 2,
            width: width,
            height: height
        )
        context.fill(Path(shadowRect), with: .color(.black.opacity(0.2)))

        // Hurdle bar
        let barRect = CGRect(
            x: point.x - width / 2,
            y: point.y - height / 2,
            width: width,
            height: barHeight
        )
        context.fill(Path(barRect), with: .color(.blue))

        // Bar highlight
        let highlightRect = CGRect(
            x: point.x - width / 2 + 2,
            y: point.y - height / 2,
            width: width - 4,
            height: barHeight * 0.4
        )
        context.fill(Path(highlightRect), with: .color(.white.opacity(0.3)))

        // Legs
        let leftLeg = CGRect(
            x: point.x - width / 2 + legWidth,
            y: point.y - height / 2,
            width: legWidth,
            height: height
        )
        let rightLeg = CGRect(
            x: point.x + width / 2 - legWidth * 2,
            y: point.y - height / 2,
            width: legWidth,
            height: height
        )
        context.fill(Path(leftLeg), with: .color(.blue.opacity(0.8)))
        context.fill(Path(rightLeg), with: .color(.blue.opacity(0.8)))
    }

    // MARK: - Mannequin

    private static func drawMannequin(context: GraphicsContext, at point: CGPoint, scale: CGFloat) {
        let size = equipmentSize * scale

        // Shadow
        let shadowPath = Path(ellipseIn: CGRect(
            x: point.x - size * 0.35,
            y: point.y + size * 0.4,
            width: size * 0.7,
            height: size * 0.2
        ))
        context.fill(shadowPath, with: .color(.black.opacity(0.2)))

        // Body (rounded rectangle / defender shape)
        let bodyWidth = size * 0.5
        let bodyHeight = size * 0.9
        let bodyRect = CGRect(
            x: point.x - bodyWidth / 2,
            y: point.y - bodyHeight / 2 + size * 0.1,
            width: bodyWidth,
            height: bodyHeight
        )
        let bodyPath = Path(roundedRect: bodyRect, cornerRadius: bodyWidth * 0.3)
        context.fill(bodyPath, with: .color(.gray))
        context.stroke(bodyPath, with: .color(.gray.opacity(0.6)), lineWidth: 1.5 * scale)

        // Body highlight
        let bodyHighlight = CGRect(
            x: point.x - bodyWidth * 0.25,
            y: point.y - bodyHeight / 2 + size * 0.15,
            width: bodyWidth * 0.3,
            height: bodyHeight * 0.4
        )
        context.fill(Path(roundedRect: bodyHighlight, cornerRadius: 2), with: .color(.white.opacity(0.2)))

        // Head (circle)
        let headRadius = size * 0.2
        let headRect = CGRect(
            x: point.x - headRadius,
            y: point.y - bodyHeight / 2 - headRadius * 0.8,
            width: headRadius * 2,
            height: headRadius * 2
        )
        let headPath = Path(ellipseIn: headRect)
        context.fill(headPath, with: .color(.gray))
        context.stroke(headPath, with: .color(.gray.opacity(0.6)), lineWidth: 1 * scale)
    }

    // MARK: - Pole

    private static func drawPole(context: GraphicsContext, at point: CGPoint, scale: CGFloat) {
        let height: CGFloat = 25 * scale
        let width: CGFloat = 4 * scale

        // Shadow
        let shadowRect = CGRect(
            x: point.x - width / 2 + 2,
            y: point.y - height / 2 + 2,
            width: width,
            height: height
        )
        context.fill(Path(shadowRect), with: .color(.black.opacity(0.2)))

        // Pole
        let poleRect = CGRect(
            x: point.x - width / 2,
            y: point.y - height / 2,
            width: width,
            height: height
        )
        context.fill(Path(poleRect), with: .color(.red))

        // Highlight
        let highlightRect = CGRect(
            x: point.x - width / 2,
            y: point.y - height / 2,
            width: width * 0.3,
            height: height
        )
        context.fill(Path(highlightRect), with: .color(.white.opacity(0.3)))

        context.stroke(Path(poleRect), with: .color(.red.opacity(0.7)), lineWidth: 0.5 * scale)
    }

    // MARK: - Rebounder

    private static func drawRebounder(
        context: GraphicsContext,
        at point: CGPoint,
        rotation: Angle,
        scale: CGFloat
    ) {
        let width: CGFloat = 38 * scale
        let height: CGFloat = 22 * scale

        // Shadow
        var shadowPath = Path()
        shadowPath.addRect(CGRect(x: -width / 2 + 3, y: -height / 2 + 3, width: width, height: height))
        var shadowTransform = CGAffineTransform(translationX: point.x, y: point.y)
        shadowTransform = shadowTransform.rotated(by: rotation.radians)
        context.fill(shadowPath.applying(shadowTransform), with: .color(.black.opacity(0.2)))

        // Frame background
        var bgPath = Path()
        bgPath.addRect(CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
        var bgTransform = CGAffineTransform(translationX: point.x, y: point.y)
        bgTransform = bgTransform.rotated(by: rotation.radians)
        context.fill(bgPath.applying(bgTransform), with: .color(.cyan.opacity(0.15)))

        var rebounderPath = Path()

        // Frame
        rebounderPath.addRect(CGRect(x: -width / 2, y: -height / 2, width: width, height: height))

        // Net pattern (diagonal lines)
        let lineCount = 6
        let spacing = width / CGFloat(lineCount)
        for i in 0...lineCount {
            let x = -width / 2 + CGFloat(i) * spacing
            rebounderPath.move(to: CGPoint(x: x, y: -height / 2))
            rebounderPath.addLine(to: CGPoint(x: x - spacing * 0.5, y: height / 2))
        }

        // Cross-hatch for net effect
        for i in 0...lineCount {
            let x = -width / 2 + CGFloat(i) * spacing
            rebounderPath.move(to: CGPoint(x: x - spacing, y: -height / 2))
            rebounderPath.addLine(to: CGPoint(x: x - spacing * 0.5, y: height / 2))
        }

        var transform = CGAffineTransform(translationX: point.x, y: point.y)
        transform = transform.rotated(by: rotation.radians)

        context.stroke(
            rebounderPath.applying(transform),
            with: .color(.cyan),
            lineWidth: 1.5 * scale
        )

        // Frame outline (thicker)
        var framePath = Path()
        framePath.addRect(CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
        context.stroke(
            framePath.applying(transform),
            with: .color(.cyan),
            lineWidth: 2.5 * scale
        )
    }

    // MARK: - Wall

    private static func drawWall(context: GraphicsContext, at point: CGPoint, scale: CGFloat) {
        let width: CGFloat = 45 * scale
        let height: CGFloat = 7 * scale

        // Shadow
        let shadowRect = CGRect(
            x: point.x - width / 2 + 2,
            y: point.y - height / 2 + 2,
            width: width,
            height: height
        )
        context.fill(Path(shadowRect), with: .color(.black.opacity(0.25)))

        let wallRect = CGRect(
            x: point.x - width / 2,
            y: point.y - height / 2,
            width: width,
            height: height
        )

        // Brick base color
        context.fill(Path(wallRect), with: .color(.brown))

        // Individual bricks for texture
        let brickWidth = width / 6
        let brickHeight = height / 2
        for row in 0..<2 {
            let offsetX = row == 1 ? brickWidth / 2 : 0
            for col in 0..<7 {
                let brickX = point.x - width / 2 + CGFloat(col) * brickWidth - offsetX
                let brickY = point.y - height / 2 + CGFloat(row) * brickHeight

                // Skip if outside bounds
                if brickX + brickWidth < point.x - width / 2 || brickX > point.x + width / 2 {
                    continue
                }

                let brickRect = CGRect(
                    x: max(brickX, point.x - width / 2),
                    y: brickY,
                    width: min(brickWidth - 1, point.x + width / 2 - brickX),
                    height: brickHeight - 0.5
                )

                // Slight color variation
                let variation = CGFloat.random(in: 0.9...1.1)
                context.fill(Path(brickRect), with: .color(.brown.opacity(variation)))
            }
        }

        // Wall outline
        context.stroke(Path(wallRect), with: .color(.darkBrown), lineWidth: 1.5 * scale)

        // Top highlight
        var topLine = Path()
        topLine.move(to: CGPoint(x: point.x - width / 2, y: point.y - height / 2))
        topLine.addLine(to: CGPoint(x: point.x + width / 2, y: point.y - height / 2))
        context.stroke(topLine, with: .color(.white.opacity(0.2)), lineWidth: 1 * scale)
    }
}

// MARK: - Color Extensions

private extension Color {
    static let darkGray = Color(white: 0.3)
    static let darkRed = Color(red: 0.6, green: 0, blue: 0)
    static let darkBrown = Color(red: 0.4, green: 0.25, blue: 0.1)
    static let brown = Color(red: 0.6, green: 0.4, blue: 0.2)
}
