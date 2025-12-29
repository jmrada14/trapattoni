import SwiftUI
import SwiftData

/// Renders drawing paths (arrows, lines, zones) on the tactical board
struct DrawingPathView: View {
    let drawing: DrawingPath
    let boardSize: CGSize
    var isEraserActive: Bool = false

    var body: some View {
        ZStack {
            // Invisible hit area for eraser - follows the path with generous padding
            if isEraserActive {
                hitAreaPath
                    .stroke(Color.clear, lineWidth: 30) // Wide hit area
                    .contentShape(hitAreaPath.stroke(style: StrokeStyle(lineWidth: 30)))
            }

            // Visual rendering
            Canvas { context, size in
                guard drawing.points.count >= 2 else { return }

                let scaledPoints = drawing.points.map { point in
                    CGPoint(x: point.x * boardSize.width, y: point.y * boardSize.height)
                }

                switch drawing.pathType {
                case .arrow, .passLine:
                    drawArrow(context: context, points: scaledPoints)
                case .line:
                    drawLine(context: context, points: scaledPoints)
                case .curvedArrow:
                    drawCurvedArrow(context: context, points: scaledPoints)
                case .zone:
                    drawZone(context: context, points: scaledPoints)
                case .freehand:
                    drawFreehand(context: context, points: scaledPoints)
                case .dottedRun:
                    drawDottedRun(context: context, points: scaledPoints)
                }
            }
            .allowsHitTesting(false)
        }
    }

    /// Creates a path shape for hit testing
    private var hitAreaPath: Path {
        let scaledPoints = drawing.points.map { point in
            CGPoint(x: point.x * boardSize.width, y: point.y * boardSize.height)
        }

        var path = Path()
        guard scaledPoints.count >= 2 else { return path }

        path.move(to: scaledPoints[0])
        for point in scaledPoints.dropFirst() {
            path.addLine(to: point)
        }

        // Close path for zones
        if drawing.pathType == .zone {
            path.closeSubpath()
        }

        return path
    }

    // MARK: - Arrow Drawing

    private func drawArrow(context: GraphicsContext, points: [CGPoint]) {
        var path = Path()
        path.move(to: points[0])

        for point in points.dropFirst() {
            path.addLine(to: point)
        }

        // Draw main line
        let strokeStyle = StrokeStyle(
            lineWidth: drawing.strokeWidth,
            lineCap: .round,
            lineJoin: .round,
            dash: drawing.isDashed ? [10, 5] : []
        )
        context.stroke(path, with: .color(drawing.strokeColor.color), style: strokeStyle)

        // Draw arrow head
        if let lastPoint = points.last, points.count >= 2 {
            let secondLast = points[points.count - 2]
            drawArrowHead(context: context, from: secondLast, to: lastPoint)
        }
    }

    private func drawArrowHead(context: GraphicsContext, from: CGPoint, to: CGPoint) {
        let angle = atan2(to.y - from.y, to.x - from.x)
        let arrowLength: CGFloat = 15
        let arrowAngle: CGFloat = .pi / 6

        var arrowPath = Path()
        arrowPath.move(to: to)
        arrowPath.addLine(to: CGPoint(
            x: to.x - arrowLength * cos(angle - arrowAngle),
            y: to.y - arrowLength * sin(angle - arrowAngle)
        ))
        arrowPath.addLine(to: CGPoint(
            x: to.x - arrowLength * cos(angle + arrowAngle),
            y: to.y - arrowLength * sin(angle + arrowAngle)
        ))
        arrowPath.closeSubpath()

        context.fill(arrowPath, with: .color(drawing.strokeColor.color))
    }

    // MARK: - Line Drawing

    private func drawLine(context: GraphicsContext, points: [CGPoint]) {
        var path = Path()
        path.move(to: points[0])

        for point in points.dropFirst() {
            path.addLine(to: point)
        }

        let strokeStyle = StrokeStyle(
            lineWidth: drawing.strokeWidth,
            lineCap: .round,
            lineJoin: .round,
            dash: drawing.isDashed ? [10, 5] : []
        )
        context.stroke(path, with: .color(drawing.strokeColor.color), style: strokeStyle)
    }

    // MARK: - Curved Arrow Drawing

    private func drawCurvedArrow(context: GraphicsContext, points: [CGPoint]) {
        guard points.count >= 2 else { return }

        var path = Path()
        path.move(to: points[0])

        if points.count == 2 {
            // Simple curve between two points
            let start = points[0]
            let end = points[1]
            let midX = (start.x + end.x) / 2
            let midY = (start.y + end.y) / 2
            let controlOffset = abs(end.x - start.x) * 0.3

            path.addQuadCurve(
                to: end,
                control: CGPoint(x: midX, y: midY - controlOffset)
            )
        } else {
            // Smooth curve through multiple points
            for i in 1..<points.count {
                let current = points[i]
                let previous = points[i - 1]
                let midPoint = CGPoint(
                    x: (previous.x + current.x) / 2,
                    y: (previous.y + current.y) / 2
                )

                if i == 1 {
                    path.addLine(to: midPoint)
                } else {
                    path.addQuadCurve(to: midPoint, control: previous)
                }
            }
            path.addLine(to: points.last!)
        }

        // Draw the curved line
        let strokeStyle = StrokeStyle(
            lineWidth: drawing.strokeWidth,
            lineCap: .round,
            lineJoin: .round
        )
        context.stroke(path, with: .color(drawing.strokeColor.color), style: strokeStyle)

        // Draw arrow head at the end
        if points.count >= 2 {
            let lastPoint = points.last!
            let secondLast = points.count > 2 ? points[points.count - 2] : points[0]
            drawArrowHead(context: context, from: secondLast, to: lastPoint)
        }
    }

    // MARK: - Zone Drawing

    private func drawZone(context: GraphicsContext, points: [CGPoint]) {
        guard points.count >= 3 else { return }

        var path = Path()
        path.move(to: points[0])

        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()

        // Fill with semi-transparent color
        context.fill(path, with: .color(drawing.strokeColor.color.opacity(drawing.fillOpacity)))

        // Stroke the outline
        let strokeStyle = StrokeStyle(
            lineWidth: drawing.strokeWidth,
            lineCap: .round,
            lineJoin: .round,
            dash: [8, 4]
        )
        context.stroke(path, with: .color(drawing.strokeColor.color), style: strokeStyle)
    }

    // MARK: - Freehand Drawing

    private func drawFreehand(context: GraphicsContext, points: [CGPoint]) {
        var path = Path()
        path.move(to: points[0])

        // Smooth the freehand path
        if points.count > 2 {
            for i in 1..<points.count - 1 {
                let p0 = points[i - 1]
                let p1 = points[i]
                let p2 = points[i + 1]

                let midPoint1 = CGPoint(x: (p0.x + p1.x) / 2, y: (p0.y + p1.y) / 2)
                let midPoint2 = CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)

                if i == 1 {
                    path.addLine(to: midPoint1)
                }
                path.addQuadCurve(to: midPoint2, control: p1)
            }
            path.addLine(to: points.last!)
        } else {
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }

        let strokeStyle = StrokeStyle(
            lineWidth: drawing.strokeWidth,
            lineCap: .round,
            lineJoin: .round
        )
        context.stroke(path, with: .color(drawing.strokeColor.color), style: strokeStyle)
    }

    // MARK: - Dotted Run Drawing

    private func drawDottedRun(context: GraphicsContext, points: [CGPoint]) {
        var path = Path()
        path.move(to: points[0])

        for point in points.dropFirst() {
            path.addLine(to: point)
        }

        // Dotted line style
        let strokeStyle = StrokeStyle(
            lineWidth: drawing.strokeWidth,
            lineCap: .round,
            lineJoin: .round,
            dash: [4, 8]
        )
        context.stroke(path, with: .color(drawing.strokeColor.color), style: strokeStyle)

        // Draw small circles at key points
        let circleRadius: CGFloat = 4
        for point in points {
            let circlePath = Path(ellipseIn: CGRect(
                x: point.x - circleRadius,
                y: point.y - circleRadius,
                width: circleRadius * 2,
                height: circleRadius * 2
            ))
            context.fill(circlePath, with: .color(drawing.strokeColor.color))
        }

        // Arrow head at end
        if let lastPoint = points.last, points.count >= 2 {
            let secondLast = points[points.count - 2]
            drawArrowHead(context: context, from: secondLast, to: lastPoint)
        }
    }
}

// MARK: - Preview

#Preview("Drawing Paths") {
    ZStack {
        Color.green.opacity(0.5)

        // Arrow
        DrawingPathView(
            drawing: DrawingPath(
                pathType: .arrow,
                points: [PathPoint(x: 0.1, y: 0.5), PathPoint(x: 0.4, y: 0.3)],
                strokeColor: .white
            ),
            boardSize: CGSize(width: 400, height: 300)
        )

        // Zone
        DrawingPathView(
            drawing: DrawingPath(
                pathType: .zone,
                points: [
                    PathPoint(x: 0.5, y: 0.2),
                    PathPoint(x: 0.8, y: 0.3),
                    PathPoint(x: 0.7, y: 0.6),
                    PathPoint(x: 0.5, y: 0.5)
                ],
                strokeColor: .yellow,
                fillOpacity: 0.3
            ),
            boardSize: CGSize(width: 400, height: 300)
        )

        // Curved Arrow
        DrawingPathView(
            drawing: DrawingPath(
                pathType: .curvedArrow,
                points: [PathPoint(x: 0.2, y: 0.8), PathPoint(x: 0.5, y: 0.7)],
                strokeColor: .red
            ),
            boardSize: CGSize(width: 400, height: 300)
        )
    }
    .frame(width: 400, height: 300)
}
