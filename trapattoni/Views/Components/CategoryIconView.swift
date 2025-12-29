import SwiftUI

struct CategoryIconView: View {
    let category: ExerciseCategory
    var size: Size = .medium

    enum Size {
        case small, medium, large

        var iconFont: Font {
            switch self {
            case .small: return .caption
            case .medium: return .body
            case .large: return .title2
            }
        }

        var padding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 12
            }
        }
    }

    private var categoryColor: Color {
        switch category {
        case .dribbling: return .blue
        case .passing: return .green
        case .shooting: return .red
        case .firstTouch: return .purple
        case .fitnessConditioning: return .orange
        case .goalkeeping: return .yellow
        case .defending: return .indigo
        case .setPieces: return .pink
        }
    }

    var body: some View {
        Image(systemName: category.iconName)
            .font(size.iconFont)
            .foregroundStyle(categoryColor)
            .padding(size.padding)
            .background(categoryColor.opacity(0.15))
            .clipShape(Circle())
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            ForEach(ExerciseCategory.allCases) { category in
                CategoryIconView(category: category, size: .small)
            }
        }

        HStack(spacing: 12) {
            ForEach(ExerciseCategory.allCases) { category in
                CategoryIconView(category: category, size: .medium)
            }
        }

        HStack(spacing: 12) {
            ForEach(ExerciseCategory.allCases.prefix(4)) { category in
                CategoryIconView(category: category, size: .large)
            }
        }
    }
    .padding()
}
