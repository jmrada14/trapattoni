import SwiftUI

struct ExerciseFilterView: View {
    @Bindable var filter: ExerciseFilter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Quick filters
                Section("filter.filters".localized) {
                    Toggle("filter.favorites".localized, isOn: $filter.showFavoritesOnly)
                    Toggle("filter.userCreated".localized, isOn: $filter.showUserCreatedOnly)
                }

                // Categories
                Section("filter.categories".localized) {
                    ForEach(ExerciseCategory.allCases) { category in
                        MultiSelectRow(
                            title: category.localizedName,
                            iconName: category.iconName,
                            isSelected: filter.selectedCategories.contains(category)
                        ) {
                            toggle(&filter.selectedCategories, category)
                        }
                    }
                }

                // Training Type
                Section("filter.trainingTypes".localized) {
                    ForEach(TrainingType.allCases) { type in
                        MultiSelectRow(
                            title: type.localizedName,
                            iconName: type.iconName,
                            isSelected: filter.selectedTrainingTypes.contains(type)
                        ) {
                            toggle(&filter.selectedTrainingTypes, type)
                        }
                    }
                }

                // Skill Level
                Section("filter.skillLevels".localized) {
                    ForEach(SkillLevel.allCases) { level in
                        MultiSelectRow(
                            title: level.localizedName,
                            isSelected: filter.selectedSkillLevels.contains(level)
                        ) {
                            toggle(&filter.selectedSkillLevels, level)
                        }
                    }
                }

                // Duration
                Section("filter.durations".localized) {
                    ForEach(Duration.allCases) { duration in
                        MultiSelectRow(
                            title: duration.localizedName,
                            iconName: duration.iconName,
                            isSelected: filter.selectedDurations.contains(duration)
                        ) {
                            toggle(&filter.selectedDurations, duration)
                        }
                    }
                }

                // Space Required
                Section("filter.space".localized) {
                    ForEach(SpaceRequired.allCases) { space in
                        MultiSelectRow(
                            title: space.localizedName,
                            iconName: space.iconName,
                            isSelected: filter.selectedSpaces.contains(space)
                        ) {
                            toggle(&filter.selectedSpaces, space)
                        }
                    }
                }

                // Equipment
                Section("filter.equipment".localized) {
                    ForEach(Equipment.allCases) { item in
                        MultiSelectRow(
                            title: item.localizedName,
                            iconName: item.iconName,
                            isSelected: filter.selectedEquipment.contains(item)
                        ) {
                            toggle(&filter.selectedEquipment, item)
                        }
                    }
                }
            }
            .navigationTitle("filter.filters".localized)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("filter.clear".localized) {
                        filter.reset()
                    }
                    .disabled(!filter.hasActiveFilters)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                }
            }
            .observeLanguageChanges()
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
