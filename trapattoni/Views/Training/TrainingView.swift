import SwiftUI
import SwiftData

struct TrainingView: View {
    @State private var selectedTab: TrainingTab = .sessions

    enum TrainingTab: CaseIterable {
        case sessions
        case plans

        var localizedName: String {
            switch self {
            case .sessions: return "tab.sessions".localized
            case .plans: return "plans.title".localized
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Segmented picker
            Picker("", selection: $selectedTab) {
                ForEach(TrainingTab.allCases, id: \.self) { tab in
                    Text(tab.localizedName).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)

            // Content - using existing views
            Group {
                switch selectedTab {
                case .sessions:
                    SessionBuilderView()
                case .plans:
                    TrainingPlansView()
                }
            }
        }
        .observeLanguageChanges()
    }
}

#Preview {
    TrainingView()
        .modelContainer(for: [TrainingSession.self, TrainingPlan.self], inMemory: true)
}
