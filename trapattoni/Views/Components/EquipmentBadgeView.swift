import SwiftUI

struct EquipmentBadgeView: View {
    let equipment: Equipment
    var style: Style = .compact

    enum Style {
        case compact
        case large
    }

    var body: some View {
        switch style {
        case .compact:
            Image(systemName: equipment.iconName)
                .font(.caption)
                .foregroundStyle(.secondary)
        case .large:
            Label(equipment.rawValue, systemImage: equipment.iconName)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 8) {
            EquipmentBadgeView(equipment: .ball, style: .compact)
            EquipmentBadgeView(equipment: .cones, style: .compact)
            EquipmentBadgeView(equipment: .goal, style: .compact)
        }

        VStack(spacing: 8) {
            EquipmentBadgeView(equipment: .ball, style: .large)
            EquipmentBadgeView(equipment: .cones, style: .large)
            EquipmentBadgeView(equipment: .ladder, style: .large)
        }
    }
    .padding()
}
