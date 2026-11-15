import SwiftUI

/// The view receives authoritative weekly progress, not a sum of current book pages.
struct WeeklyGoalSection: View {
    @Binding var showsOnHome: Bool
    @Binding var targetPages: Int
    @Binding var enabled: Bool
    let progress: WeeklyReadingGoal?
    let scheduledDates: [Date]
    let isLoading: Bool
    let errorMessage: String?
    let permissionGranted: Bool
    let requestingPermission: Bool
    let refresh: () -> Void

    var body: some View {
        Section {
            Toggle("weekly_goal_show_home", isOn: $showsOnHome)
            Text("weekly_goal_show_home_help")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Stepper(value: $targetPages, in: 10...5000, step: 10) {
                Text(String(format: String(localized: "weekly_goal_target"), targetPages))
            }
            Toggle("weekly_goal_enable", isOn: $enabled)
                .disabled(requestingPermission)
            if let progress {
                ProgressView(value: progress.fraction)
                    .accessibilityLabel("weekly_goal_progress")
                    .accessibilityValue(Text(String(format: String(localized: "weekly_goal_count"), progress.pagesRead, progress.targetPages)))
                Text(String(format: String(localized: "weekly_goal_count"), progress.pagesRead, progress.targetPages))
                if progress.isComplete {
                    Label("weekly_goal_completed", systemImage: "checkmark.circle.fill")
                } else {
                    Text(String(format: String(localized: "weekly_goal_remaining"), progress.remainingPages))
                        .foregroundStyle(.secondary)
                }
            }
            if isLoading { ProgressView() }
            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.secondary)
                Button("reminders_retry", action: refresh)
            } else if enabled {
                if !permissionGranted {
                    Text("reminders_waiting_permission")
                } else if let next = scheduledDates.first {
                    LabeledContent("weekly_goal_next") {
                        Text(next, format: .dateTime.weekday().day().month().hour().minute())
                    }
                } else if !isLoading, progress != nil {
                    Text("weekly_goal_no_pending").font(.footnote).foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("weekly_goal_title")
        } footer: {
            Text("weekly_goal_rule")
        }
    }
}
