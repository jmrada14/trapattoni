import SwiftUI

struct ExerciseFilterView: View {
    @Bindable var filter: ExerciseFilter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Quick filters
                Section("Quick Filters") {
                    Toggle("Favorites Only", isOn: $filter.showFavoritesOnly)
                    Toggle("My Exercises Only", isOn: $filter.showUserCreatedOnly)
                }

                // Categories
                Section("Categories") {
                    ForEach(ExerciseCategory.allCases) { category in
                        MultiSelectRow(
                            title: category.rawValue,
                            iconName: category.iconName,
                            isSelected: filter.selectedCategories.contains(category)
                        ) {
                            toggle(&filter.selectedCategories, category)
                        }
                    }
                }

                // Training Type
                Section("Training Type") {
                    ForEach(TrainingType.allCases) { type in
                        MultiSelectRow(
                            title: type.rawValue,
                            iconName: type.iconName,
                            isSelected: filter.selectedTrainingTypes.contains(type)
                        ) {
                            toggle(&filter.selectedTrainingTypes, type)
                        }
                    }
                }

                // Skill Level
                Section("Skill Level") {
                    ForEach(SkillLevel.allCases) { level in
                        MultiSelectRow(
                            title: level.rawValue,
                            isSelected: filter.selectedSkillLevels.contains(level)
                        ) {
                            toggle(&filter.selectedSkillLevels, level)
                        }
                    }
                }

                // Duration
                Section("Duration") {
                    ForEach(Duration.allCases) { duration in
                        MultiSelectRow(
                            title: duration.rawValue,
                            iconName: duration.iconName,
                            isSelected: filter.selectedDurations.contains(duration)
                        ) {
                            toggle(&filter.selectedDurations, duration)
                        }
                    }
                }

                // Space Required
                Section("Space Required") {
                    ForEach(SpaceRequired.allCases) { space in
                        MultiSelectRow(
                            title: space.rawValue,
                            iconName: space.iconName,
                            isSelected: filter.selectedSpaces.contains(space)
                        ) {
                            toggle(&filter.selectedSpaces, space)
                        }
                    }
                }

                // Equipment
                Section("Equipment") {
                    ForEach(Equipment.allCases) { item in
                        MultiSelectRow(
                            title: item.rawValue,
                            iconName: item.iconName,
                            isSelected: filter.selectedEquipment.contains(item)
                        ) {
                            toggle(&filter.selectedEquipment, item)
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        filter.reset()
                    }
                    .disabled(!filter.hasActiveFilters)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func toggle<T: Hashable>(_ set: inout Set<T>, _ item: T) {
        if set.contains(item) {
            set.remove(item)
        } else {
            set.insert(item)
        }
    }
}

// MARK: - Multi-select Row Component

struct MultiSelectRow: View {
    let title: String
    var iconName: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if let iconName {
                    Image(systemName: iconName)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                }

                Text(title)
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                        .fontWeight(.semibold)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ExerciseFilterView(filter: ExerciseFilter())
}
