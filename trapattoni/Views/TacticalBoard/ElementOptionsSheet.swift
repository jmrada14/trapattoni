import SwiftUI
import SwiftData

/// Sheet for editing element properties
struct ElementOptionsSheet: View {
    @Bindable var element: BoardElement
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Element info
                Section("Element") {
                    HStack {
                        Image(systemName: element.elementType.icon)
                            .foregroundStyle(element.teamColor.color)
                            .frame(width: 30)
                        Text(element.elementType.rawValue)
                    }
                }

                // Team color (for players)
                if element.elementType == .player || element.elementType == .goalkeeper {
                    Section("Team") {
                        Picker("Team Color", selection: $element.teamColor) {
                            ForEach(TeamColor.allCases, id: \.self) { color in
                                HStack {
                                    Circle()
                                        .fill(color.color)
                                        .frame(width: 20, height: 20)
                                    Text(color.rawValue)
                                }
                                .tag(color)
                            }
                        }
                        .pickerStyle(.inline)
                    }

                    Section("Number") {
                        Stepper(
                            value: Binding(
                                get: { element.number ?? 1 },
                                set: { element.number = $0 }
                            ),
                            in: 1...99
                        ) {
                            HStack {
                                Text("Jersey Number")
                                Spacer()
                                Text("\(element.number ?? 1)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Label
                Section("Label") {
                    TextField("Optional label", text: $element.label)
                }

                // Transform
                Section("Transform") {
                    VStack(alignment: .leading) {
                        Text("Rotation: \(Int(element.rotation))°")
                        Slider(value: $element.rotation, in: 0...360, step: 15)
                    }

                    VStack(alignment: .leading) {
                        Text("Scale: \(element.scale, specifier: "%.1f")x")
                        Slider(value: $element.scale, in: 0.5...2.0, step: 0.1)
                    }
                }

                // Delete
                Section {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Delete Element", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Element")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium])
        #else
        .frame(minWidth: 350, minHeight: 400)
        #endif
    }
}

// MARK: - Equipment Picker Sheet

struct EquipmentPickerSheet: View {
    @Binding var selectedType: ElementType
    let onSelect: (ElementType) -> Void

    @Environment(\.dismiss) private var dismiss

    private let equipmentTypes: [ElementType] = [
        .cone, .flag, .mannequin, .ladder, .goal, .miniGoal
    ]

    var body: some View {
        NavigationStack {
            List(equipmentTypes, id: \.self) { type in
                Button {
                    onSelect(type)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: type.icon)
                            .frame(width: 30)
                        Text(type.rawValue)
                        Spacer()
                        if selectedType == type {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }
            .navigationTitle("Select Equipment")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium])
        #else
        .frame(minWidth: 300, minHeight: 300)
        #endif
    }
}

// MARK: - Preview

#Preview("Element Options") {
    ElementOptionsSheet(
        element: BoardElement(
            elementType: .player,
            position: CGPoint(x: 0.5, y: 0.5),
            teamColor: .home,
            number: 10
        ),
        onDelete: {}
    )
}
