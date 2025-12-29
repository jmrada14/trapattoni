import SwiftUI

struct SkillLevelBadge: View {
    let level: SkillLevel

    private var color: Color {
        switch level {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }

    var body: some View {
        Text(level.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 12) {
        SkillLevelBadge(level: .beginner)
        SkillLevelBadge(level: .intermediate)
        SkillLevelBadge(level: .advanced)
    }
    .padding()
}
