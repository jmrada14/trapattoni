import SwiftUI

/// Draws the football pitch/field background
struct FieldRenderer {

    // MARK: - Colors

    private static let grassLight = Color(red: 0.22, green: 0.55, blue: 0.24)
    private static let grassDark = Color(red: 0.18, green: 0.48, blue: 0.20)
    private static let lineColor = Color.white.opacity(0.9)
    private static let lineWidth: CGFloat = 2

    // MARK: - Main Drawing

    /// Draw the complete football field
    static func drawField(context: GraphicsContext, size: CGSize, halfField: Bool = false) {
        // Draw grass with stripe pattern
        drawGrass(context: context, size: size)

        // Draw field markings
        drawFieldMarkings(context: context, size: size, halfField: halfField)
    }

    // MARK: - Grass

    private static func drawGrass(context: GraphicsContext, size: CGSize) {
        // Base grass color
        let grassRect = Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 12)
        context.fill(grassRect, with: .color(grassLight))

        // Stripe pattern for realism
        let stripeCount = 8
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
    }

    // MARK: - Field Markings

    private static func drawFieldMarkings(context: GraphicsContext, size: CGSize, halfField: Bool) {
        let padding: CGFloat = 20
        let fieldRect = CGRect(
            x: padding,
            y: padding,
            width: size.width - padding * 2,
            height: size.height - padding * 2
        )

        // Outer boundary
        drawBoundary(context: context, rect: fieldRect)

        if halfField {
            // Half field - show penalty area and goal
            drawHalfFieldMarkings(context: context, fieldRect: fieldRect)
        } else {
            // Full field markings
            drawFullFieldMarkings(context: context, fieldRect: fieldRect)
        }
    }

    private static func drawBoundary(context: GraphicsContext, rect: CGRect) {
        var boundaryPath = Path()
        boundaryPath.addRoundedRect(in: rect, cornerSize: CGSize(width: 4, height: 4))
        context.stroke(boundaryPath, with: .color(lineColor), lineWidth: lineWidth)
    }

    private static func drawFullFieldMarkings(context: GraphicsContext, fieldRect: CGRect) {
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
            x: fieldRect.midX - 3,
            y: fieldRect.midY - 3,
            width: 6,
            height: 6
        ))
        context.fill(centerSpot, with: .color(lineColor))

        // Top penalty area (goal at top)
        drawPenaltyArea(context: context, fieldRect: fieldRect, atTop: true)

        // Bottom penalty area
        drawPenaltyArea(context: context, fieldRect: fieldRect, atTop: false)
    }

    private static func drawHalfFieldMarkings(context: GraphicsContext, fieldRect: CGRect) {
        // Penalty area at top
        drawPenaltyArea(context: context, fieldRect: fieldRect, atTop: true, enlarged: true)

        // Center arc at bottom
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
    }

    private static func drawPenaltyArea(
        context: GraphicsContext,
        fieldRect: CGRect,
        atTop: Bool,
        enlarged: Bool = false
    ) {
        let penaltyWidth = fieldRect.width * (enlarged ? 0.65 : 0.55)
        let penaltyHeight = fieldRect.height * (enlarged ? 0.25 : 0.18)
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

            // Goal area (6-yard box)
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
                x: fieldRect.midX - 3,
                y: spotY - 3,
                width: 6,
                height: 6
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

            // Goal posts
            drawGoalPosts(context: context, centerX: fieldRect.midX, y: fieldRect.minY - 5)

        } else {
            // Penalty box at bottom
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
                x: fieldRect.midX - 3,
                y: spotY - 3,
                width: 6,
                height: 6
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
        }
    }

    private static func drawGoalPosts(context: GraphicsContext, centerX: CGFloat, y: CGFloat) {
        let goalWidth: CGFloat = 60
        let postWidth: CGFloat = 4

        // Left post
        let leftPost = Path(roundedRect: CGRect(
            x: centerX - goalWidth / 2 - postWidth / 2,
            y: y - 8,
            width: postWidth,
            height: 12
        ), cornerRadius: 1)
        context.fill(leftPost, with: .color(.white))

        // Right post
        let rightPost = Path(roundedRect: CGRect(
            x: centerX + goalWidth / 2 - postWidth / 2,
            y: y - 8,
            width: postWidth,
            height: 12
        ), cornerRadius: 1)
        context.fill(rightPost, with: .color(.white))

        // Crossbar
        let crossbar = Path(roundedRect: CGRect(
            x: centerX - goalWidth / 2,
            y: y - 8,
            width: goalWidth,
            height: postWidth
        ), cornerRadius: 1)
        context.fill(crossbar, with: .color(.white))

        // Net background
        let netRect = CGRect(
            x: centerX - goalWidth / 2 + postWidth,
            y: y - 20,
            width: goalWidth - postWidth * 2,
            height: 15
        )
        context.fill(Path(netRect), with: .color(.white.opacity(0.2)))
    }
}
