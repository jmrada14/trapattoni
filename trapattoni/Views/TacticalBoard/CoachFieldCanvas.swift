import SwiftUI

/// Renders the football field background for the coach's tactical board
struct CoachFieldCanvas: View {
    let fieldType: FieldType

    // Field colors
    private let grassLight = Color(red: 0.18, green: 0.52, blue: 0.22)
    private let grassDark = Color(red: 0.15, green: 0.45, blue: 0.18)
    private let lineColor = Color.white.opacity(0.9)
    private let lineWidth: CGFloat = 2

    var body: some View {
        Canvas { context, size in
            // Draw grass with stripes
            drawGrass(context: context, size: size)

            // Draw field markings based on type
            switch fieldType {
            case .fullField:
                drawFullField(context: context, size: size)
            case .halfField:
                drawHalfField(context: context, size: size)
            case .thirdField:
                drawThirdField(context: context, size: size)
            case .penaltyBox:
                drawPenaltyBoxArea(context: context, size: size)
            }
        }
    }

    // MARK: - Grass Drawing

    private func drawGrass(context: GraphicsContext, size: CGSize) {
        // Base grass
        let grassRect = Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 12)
        context.fill(grassRect, with: .color(grassLight))

        // Stripe pattern
        let stripeCount = 10
        let stripeHeight = size.height / CGFloat(stripeCount)

        for i in stride(from: 0, to: stripeCount, by: 2) {
            let stripeRect = CGRect(
                x: 0,
                y: CGFloat(i) * stripeHeight,
                width: size.width,
                height: stripeHeight
            )
            context.fill(Path(stripeRect), with: .color(grassDark))
        }

        // Subtle grass texture overlay
        context.fill(grassRect, with: .color(.white.opacity(0.02)))
    }

    // MARK: - Full Field

    private func drawFullField(context: GraphicsContext, size: CGSize) {
        let padding: CGFloat = 15
        let fieldRect = CGRect(
            x: padding,
            y: padding,
            width: size.width - padding * 2,
            height: size.height - padding * 2
        )

        // Outer boundary
        drawBoundary(context: context, rect: fieldRect)

        // Center line
        var centerLine = Path()
        centerLine.move(to: CGPoint(x: fieldRect.minX, y: fieldRect.midY))
        centerLine.addLine(to: CGPoint(x: fieldRect.maxX, y: fieldRect.midY))
        context.stroke(centerLine, with: .color(lineColor), lineWidth: lineWidth)

        // Center circle
        let centerCircleRadius = fieldRect.width * 0.12
        var centerCircle = Path()
        centerCircle.addEllipse(in: CGRect(
            x: fieldRect.midX - centerCircleRadius,
            y: fieldRect.midY - centerCircleRadius,
            width: centerCircleRadius * 2,
            height: centerCircleRadius * 2
        ))
        context.stroke(centerCircle, with: .color(lineColor), lineWidth: lineWidth)

        // Center spot
        let centerSpot = Path(ellipseIn: CGRect(
            x: fieldRect.midX - 4,
            y: fieldRect.midY - 4,
            width: 8,
            height: 8
        ))
        context.fill(centerSpot, with: .color(lineColor))

        // Penalty areas
        drawPenaltyArea(context: context, fieldRect: fieldRect, atTop: true)
        drawPenaltyArea(context: context, fieldRect: fieldRect, atTop: false)

        // Corner arcs
        drawCornerArcs(context: context, fieldRect: fieldRect)
    }

    // MARK: - Half Field

    private func drawHalfField(context: GraphicsContext, size: CGSize) {
        let padding: CGFloat = 15
        let fieldRect = CGRect(
            x: padding,
            y: padding,
            width: size.width - padding * 2,
            height: size.height - padding * 2
        )

        // Outer boundary
        drawBoundary(context: context, rect: fieldRect)

        // Penalty area at top
        drawPenaltyArea(context: context, fieldRect: fieldRect, atTop: true, enlarged: true)

        // Half circle at bottom (center circle arc)
        let arcRadius = fieldRect.width * 0.15
        var centerArc = Path()
        centerArc.addArc(
            center: CGPoint(x: fieldRect.midX, y: fieldRect.maxY),
            radius: arcRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: true
        )
        context.stroke(centerArc, with: .color(lineColor), lineWidth: lineWidth)

        // Corner arcs (top only)
        drawCornerArc(context: context, at: CGPoint(x: fieldRect.minX, y: fieldRect.minY), quadrant: .topLeft)
        drawCornerArc(context: context, at: CGPoint(x: fieldRect.maxX, y: fieldRect.minY), quadrant: .topRight)
    }

    // MARK: - Third Field

    private func drawThirdField(context: GraphicsContext, size: CGSize) {
        let padding: CGFloat = 15
        let fieldRect = CGRect(
            x: padding,
            y: padding,
            width: size.width - padding * 2,
            height: size.height - padding * 2
        )

        // Outer boundary
        drawBoundary(context: context, rect: fieldRect)

        // Simplified penalty area
        let penaltyWidth = fieldRect.width * 0.6
        let penaltyHeight = fieldRect.height * 0.3

        let penaltyRect = CGRect(
            x: fieldRect.midX - penaltyWidth / 2,
            y: fieldRect.minY,
            width: penaltyWidth,
            height: penaltyHeight
        )
        context.stroke(Path(penaltyRect), with: .color(lineColor), lineWidth: lineWidth)

        // Goal area
        let goalAreaWidth = fieldRect.width * 0.3
        let goalAreaHeight = fieldRect.height * 0.12
        let goalAreaRect = CGRect(
            x: fieldRect.midX - goalAreaWidth / 2,
            y: fieldRect.minY,
            width: goalAreaWidth,
            height: goalAreaHeight
        )
        context.stroke(Path(goalAreaRect), with: .color(lineColor), lineWidth: lineWidth)

        // Goal
        drawGoal(context: context, centerX: fieldRect.midX, y: fieldRect.minY)
    }

    // MARK: - Penalty Box Area

    private func drawPenaltyBoxArea(context: GraphicsContext, size: CGSize) {
        let padding: CGFloat = 15
        let fieldRect = CGRect(
            x: padding,
            y: padding,
            width: size.width - padding * 2,
            height: size.height - padding * 2
        )

        // Outer boundary
        drawBoundary(context: context, rect: fieldRect)

        // Penalty box
        let penaltyWidth = fieldRect.width * 0.75
        let penaltyHeight = fieldRect.height * 0.5

        let penaltyRect = CGRect(
            x: fieldRect.midX - penaltyWidth / 2,
            y: fieldRect.minY,
            width: penaltyWidth,
            height: penaltyHeight
        )
        context.stroke(Path(penaltyRect), with: .color(lineColor), lineWidth: lineWidth)

        // Goal area
        let goalAreaWidth = fieldRect.width * 0.35
        let goalAreaHeight = fieldRect.height * 0.18
        let goalAreaRect = CGRect(
            x: fieldRect.midX - goalAreaWidth / 2,
            y: fieldRect.minY,
            width: goalAreaWidth,
            height: goalAreaHeight
        )
        context.stroke(Path(goalAreaRect), with: .color(lineColor), lineWidth: lineWidth)

        // Penalty spot
        let spotY = fieldRect.minY + penaltyHeight * 0.5
        let penaltySpot = Path(ellipseIn: CGRect(
            x: fieldRect.midX - 4,
            y: spotY - 4,
            width: 8,
            height: 8
        ))
        context.fill(penaltySpot, with: .color(lineColor))

        // Penalty arc
        let arcRadius = penaltyHeight * 0.25
        var penaltyArc = Path()
        penaltyArc.addArc(
            center: CGPoint(x: fieldRect.midX, y: spotY),
            radius: arcRadius,
            startAngle: .degrees(30),
            endAngle: .degrees(150),
            clockwise: true
        )
        context.stroke(penaltyArc, with: .color(lineColor), lineWidth: lineWidth)

        // Goal
        drawGoal(context: context, centerX: fieldRect.midX, y: fieldRect.minY)
    }

    // MARK: - Helper Methods

    private func drawBoundary(context: GraphicsContext, rect: CGRect) {
        var boundaryPath = Path()
        boundaryPath.addRoundedRect(in: rect, cornerSize: CGSize(width: 4, height: 4))
        context.stroke(boundaryPath, with: .color(lineColor), lineWidth: lineWidth)
    }

    private func drawPenaltyArea(
        context: GraphicsContext,
        fieldRect: CGRect,
        atTop: Bool,
        enlarged: Bool = false
    ) {
        let penaltyWidth = fieldRect.width * (enlarged ? 0.65 : 0.55)
        let penaltyHeight = fieldRect.height * (enlarged ? 0.28 : 0.18)
        let goalAreaWidth = fieldRect.width * 0.25
        let goalAreaHeight = fieldRect.height * 0.08

        let penaltyX = fieldRect.midX - penaltyWidth / 2
        let goalAreaX = fieldRect.midX - goalAreaWidth / 2

        if atTop {
            // Penalty box
            let penaltyRect = CGRect(
                x: penaltyX,
                y: fieldRect.minY,
                width: penaltyWidth,
                height: penaltyHeight
            )
            context.stroke(Path(penaltyRect), with: .color(lineColor), lineWidth: lineWidth)

            // Goal area
            let goalAreaRect = CGRect(
                x: goalAreaX,
                y: fieldRect.minY,
                width: goalAreaWidth,
                height: goalAreaHeight
            )
            context.stroke(Path(goalAreaRect), with: .color(lineColor), lineWidth: lineWidth)

            // Penalty spot
            let spotY = fieldRect.minY + penaltyHeight * 0.65
            let penaltySpot = Path(ellipseIn: CGRect(
                x: fieldRect.midX - 4,
                y: spotY - 4,
                width: 8,
                height: 8
            ))
            context.fill(penaltySpot, with: .color(lineColor))

            // Penalty arc
            let arcRadius = penaltyHeight * 0.35
            var penaltyArc = Path()
            penaltyArc.addArc(
                center: CGPoint(x: fieldRect.midX, y: spotY),
                radius: arcRadius,
                startAngle: .degrees(35),
                endAngle: .degrees(145),
                clockwise: true
            )
            context.stroke(penaltyArc, with: .color(lineColor), lineWidth: lineWidth)

            // Goal
            drawGoal(context: context, centerX: fieldRect.midX, y: fieldRect.minY - 5)
        } else {
            // Penalty box
            let penaltyRect = CGRect(
                x: penaltyX,
                y: fieldRect.maxY - penaltyHeight,
                width: penaltyWidth,
                height: penaltyHeight
            )
            context.stroke(Path(penaltyRect), with: .color(lineColor), lineWidth: lineWidth)

            // Goal area
            let goalAreaRect = CGRect(
                x: goalAreaX,
                y: fieldRect.maxY - goalAreaHeight,
                width: goalAreaWidth,
                height: goalAreaHeight
            )
            context.stroke(Path(goalAreaRect), with: .color(lineColor), lineWidth: lineWidth)

            // Penalty spot
            let spotY = fieldRect.maxY - penaltyHeight * 0.65
            let penaltySpot = Path(ellipseIn: CGRect(
                x: fieldRect.midX - 4,
                y: spotY - 4,
                width: 8,
                height: 8
            ))
            context.fill(penaltySpot, with: .color(lineColor))

            // Penalty arc
            let arcRadius = penaltyHeight * 0.35
            var penaltyArc = Path()
            penaltyArc.addArc(
                center: CGPoint(x: fieldRect.midX, y: spotY),
                radius: arcRadius,
                startAngle: .degrees(215),
                endAngle: .degrees(325),
                clockwise: true
            )
            context.stroke(penaltyArc, with: .color(lineColor), lineWidth: lineWidth)

            // Goal
            drawGoal(context: context, centerX: fieldRect.midX, y: fieldRect.maxY + 5, flipped: true)
        }
    }

    private func drawGoal(context: GraphicsContext, centerX: CGFloat, y: CGFloat, flipped: Bool = false) {
        let goalWidth: CGFloat = 55
        let postWidth: CGFloat = 4
        let goalDepth: CGFloat = 12

        let yOffset = flipped ? 0 : -goalDepth

        // Net background
        let netRect = CGRect(
            x: centerX - goalWidth / 2,
            y: y + yOffset,
            width: goalWidth,
            height: goalDepth
        )
        context.fill(Path(netRect), with: .color(.white.opacity(0.15)))

        // Goal posts
        let leftPost = Path(roundedRect: CGRect(
            x: centerX - goalWidth / 2 - postWidth / 2,
            y: y + yOffset,
            width: postWidth,
            height: goalDepth
        ), cornerRadius: 1)
        context.fill(leftPost, with: .color(.white))

        let rightPost = Path(roundedRect: CGRect(
            x: centerX + goalWidth / 2 - postWidth / 2,
            y: y + yOffset,
            width: postWidth,
            height: goalDepth
        ), cornerRadius: 1)
        context.fill(rightPost, with: .color(.white))

        // Crossbar
        let crossbar = Path(roundedRect: CGRect(
            x: centerX - goalWidth / 2,
            y: flipped ? y + goalDepth - postWidth : y - postWidth,
            width: goalWidth,
            height: postWidth
        ), cornerRadius: 1)
        context.fill(crossbar, with: .color(.white))
    }

    private func drawCornerArcs(context: GraphicsContext, fieldRect: CGRect) {
        drawCornerArc(context: context, at: CGPoint(x: fieldRect.minX, y: fieldRect.minY), quadrant: .topLeft)
        drawCornerArc(context: context, at: CGPoint(x: fieldRect.maxX, y: fieldRect.minY), quadrant: .topRight)
        drawCornerArc(context: context, at: CGPoint(x: fieldRect.minX, y: fieldRect.maxY), quadrant: .bottomLeft)
        drawCornerArc(context: context, at: CGPoint(x: fieldRect.maxX, y: fieldRect.maxY), quadrant: .bottomRight)
    }

    private enum Quadrant {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    private func drawCornerArc(context: GraphicsContext, at point: CGPoint, quadrant: Quadrant) {
        let arcRadius: CGFloat = 8
        var arc = Path()

        let (startAngle, endAngle): (Angle, Angle) = {
            switch quadrant {
            case .topLeft: return (.degrees(0), .degrees(90))
            case .topRight: return (.degrees(90), .degrees(180))
            case .bottomLeft: return (.degrees(270), .degrees(360))
            case .bottomRight: return (.degrees(180), .degrees(270))
            }
        }()

        arc.addArc(
            center: point,
            radius: arcRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        context.stroke(arc, with: .color(lineColor), lineWidth: lineWidth)
    }
}

// MARK: - Preview

#Preview("Full Field") {
    CoachFieldCanvas(fieldType: .fullField)
        .frame(width: 400, height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
}

#Preview("Half Field") {
    CoachFieldCanvas(fieldType: .halfField)
        .frame(width: 400, height: 340)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
}

#Preview("Penalty Box") {
    CoachFieldCanvas(fieldType: .penaltyBox)
        .frame(width: 400, height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
}
