import SwiftUI

struct HomeWeeklyGoalCard: View {
    @State private var goal = WeeklyGoalReminderService.shared
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: WeeklyReadingGoal? {
        guard let progress = goal.progress,
              progress.weekStart == WeeklyReadingGoal.start(of: Date()) else { return nil }
        return progress
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("weekly_goal_title")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppColors.titles)
                    Text(weekLabel)
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }
                Spacer(minLength: 0)
                NavigationLink {
                    ReadingRemindersView()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.accent)
                        .frame(width: 44, height: 44)
                        .background(AppColors.accent.opacity(0.09), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("home_goal_manage")
            }

            if let progress {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 20) {
                            ring(progress)
                            summary(progress)
                        }
                    } else {
                        HStack(spacing: 22) {
                            ring(progress)
                            summary(progress)
                        }
                    }
                }
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: progress.fraction)
            } else if goal.isLoading {
                HStack(spacing: 12) {
                    ProgressView().tint(AppColors.accent)
                    Text("home_goal_loading")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)
                }
                .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(String(format: String(localized: "weekly_goal_target"), goal.targetPages))
                        .font(.headline)
                    Text("home_goal_unavailable")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)
                    Button("common_retry") { Task { await goal.refresh() } }
                        .font(.subheadline.weight(.semibold))
                        .tint(AppColors.accent)
                        .frame(minHeight: 44)
                }
            }

            if let error = goal.errorMessage, progress != nil, !goal.isLoading {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(AppColors.secondaryText)
            }

            NavigationLink {
                ReadingRemindersView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: reminderIcon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.accent)
                        .frame(width: 36, height: 36)
                        .background(AppColors.accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("home_goal_reminder")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.secondaryText)
                        Text(reminderStatus)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppColors.titles)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppColors.secondaryText)
                }
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                .background(AppColors.background.opacity(0.7), in: RoundedRectangle(cornerRadius: 18))
                .contentShape(RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(AppColors.surface)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22).strokeBorder(AppColors.border, lineWidth: 1)
        }
        .task {
            if progress == nil && !goal.isLoading { await goal.refresh() }
        }
    }

    private func ring(_ progress: WeeklyReadingGoal) -> some View {
        ZStack {
            Circle().stroke(AppColors.accent.opacity(0.11), lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress.fraction)
                .stroke(AppColors.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                if progress.isComplete {
                    Image(systemName: "checkmark")
                        .font(.title2)
                        .foregroundStyle(AppColors.accent)
                }
                Text(progress.fraction, format: .percent.precision(.fractionLength(0)))
                    .font(.system(.title, design: .default, weight: .semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(AppColors.titles)
                if !progress.isComplete {
                    Text("home_goal_completed_label")
                        .font(.caption2)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
        .frame(width: 118, height: 118)
        .padding(5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("weekly_goal_progress")
        .accessibilityValue(Text(progress.fraction, format: .percent.precision(.fractionLength(0))))
    }

    private func summary(_ progress: WeeklyReadingGoal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(progress.isComplete ? String(localized: "home_goal_success") : String(localized: "home_goal_keep_going"))
                .font(.headline)
                .foregroundStyle(AppColors.titles)
            Text(String(format: String(localized: "weekly_goal_count"), progress.pagesRead, progress.targetPages))
                .font(.system(.title3, design: .default, weight: .semibold))
                .foregroundStyle(AppColors.accent)
                .monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)
            Text(progress.isComplete
                 ? String(localized: "home_goal_success_detail")
                 : String(format: String(localized: "weekly_goal_remaining"), progress.remainingPages))
                .font(.subheadline)
                .foregroundStyle(AppColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var weekLabel: String {
        let start = WeeklyReadingGoal.start(of: Date())
        let end = WeeklyReadingGoal.calendar.date(byAdding: .day, value: 6, to: start)!
        let style = Date.FormatStyle.dateTime.day().month(.abbreviated)
        return "\(start.formatted(style)) – \(end.formatted(style))"
    }

    private var reminderIcon: String {
        goal.enabled ? "bell.badge" : "bell.slash"
    }

    private var reminderStatus: String {
        if !goal.enabled { return String(localized: "home_goal_reminder_off") }
        if !goal.permissionGranted { return String(localized: "home_goal_permission") }
        if goal.isLoading { return String(localized: "home_goal_loading") }
        if goal.errorMessage != nil { return String(localized: "home_goal_reminder_review") }
        if progress?.isComplete == true { return String(localized: "home_goal_reminder_done") }
        if let next = goal.scheduledDates.first(where: { $0 > Date() }) {
            return next.formatted(.dateTime.weekday(.wide).hour().minute())
        }
        return String(localized: "weekly_goal_no_pending")
    }
}
