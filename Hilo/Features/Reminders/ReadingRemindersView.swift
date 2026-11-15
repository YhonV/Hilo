import SwiftUI
import UserNotifications

struct ReadingRemindersView: View {
    @State private var weeklyGoal = WeeklyGoalReminderService.shared
    @State private var reminders = ReadingReminderService.shared
    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            Section {
                Toggle("reminders_enable", isOn: Binding(
                    get: { reminders.enabled },
                    set: { value in Task { await reminders.setEnabled(value) } }
                ))
                .disabled(reminders.requestingPermission || weeklyGoal.requestingPermission)
                DatePicker("reminders_time", selection: Binding(
                    get: { reminders.time }, set: {
                        reminders.setTime($0)
                        weeklyGoal.setTime(hour: reminders.hour, minute: reminders.minute)
                    }
                ), displayedComponents: .hourAndMinute)
                .disabled(!reminders.enabled && !reminders.inactivityEnabled && !weeklyGoal.enabled)
            } footer: {
                Text("reminders_rule")
            }

            Section {
                Toggle("inactivity_enable", isOn: Binding(
                    get: { reminders.inactivityEnabled },
                    set: { value in Task { await reminders.setEnabled(value, inactivity: true) } }
                ))
                .disabled(reminders.requestingPermission || weeklyGoal.requestingPermission)
                Picker("inactivity_period", selection: Binding(
                    get: { reminders.inactivityDays }, set: { reminders.setInactivityDays($0) }
                )) {
                    Text("inactivity_three_days").tag(3)
                    Text("inactivity_seven_days").tag(7)
                }
                .disabled(!reminders.inactivityEnabled)
                if let date = reminders.lastReadingActivity {
                    LabeledContent("inactivity_last_activity") {
                        Text(date, format: .dateTime.day().month().year())
                    }
                }
                if reminders.inactivityEnabled {
                    if let error = reminders.activityError {
                        Text(error).font(.footnote).foregroundStyle(.secondary)
                        Button("reminders_retry") {
                            Task { await reminders.refreshActivity() }
                        }
                    }
                    if !permissionGranted {
                        Text("reminders_waiting_permission")
                    } else if let date = reminders.inactivityScheduledDate {
                        LabeledContent("inactivity_next") {
                            Text(date, format: .dateTime.day().month().hour().minute())
                        }
                    } else {
                        Text("inactivity_waiting").font(.footnote).foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("inactivity_title")
            } footer: {
                Text("inactivity_rule")
            }

            WeeklyGoalSection(
                showsOnHome: Binding(get: { weeklyGoal.showsOnHome }, set: { weeklyGoal.setShowsOnHome($0) }),
                targetPages: Binding(get: { weeklyGoal.targetPages }, set: { weeklyGoal.setTarget($0) }),
                enabled: Binding(get: { weeklyGoal.enabled }, set: { value in
                    Task {
                        await weeklyGoal.setEnabled(value)
                        reminders.reconcile()
                    }
                }),
                progress: weeklyGoal.progress,
                scheduledDates: weeklyGoal.scheduledDates,
                isLoading: weeklyGoal.isLoading,
                errorMessage: weeklyGoal.errorMessage,
                permissionGranted: weeklyGoal.permissionGranted,
                requestingPermission: weeklyGoal.requestingPermission || reminders.requestingPermission,
                refresh: { Task { await weeklyGoal.refresh() } }
            )

            Section("reminders_permissions") {
                Label(permissionLabel, systemImage: permissionGranted ? "bell.badge" : "bell.slash")
                if reminders.authorization == .denied || permissionGranted {
                    Button("reminders_open_settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                }
                if reminders.authorization == .denied {
                    Text("reminders_denied_help").font(.footnote).foregroundStyle(.secondary)
                }
            }

            Section("reminders_status") {
                if let error = reminders.errorMessage {
                    Text(error).foregroundStyle(.red)
                    Button("reminders_retry") { reminders.reconcile() }
                } else if !reminders.enabled {
                    Text("reminders_disabled")
                } else if !permissionGranted {
                    Text("reminders_waiting_permission")
                } else if !reminders.hasActiveReading {
                    Text("reminders_no_books")
                } else if reminders.scheduled {
                    Label("reminders_scheduled", systemImage: "checkmark.circle")
                } else {
                    ProgressView()
                }
            }
        }
        .tint(AppColors.accent)
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
        .navigationTitle("reminders_title")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            reminders.reconcile()
            weeklyGoal.setTime(hour: reminders.hour, minute: reminders.minute)
            await weeklyGoal.refresh()
        }
    }

    private var permissionGranted: Bool {
        [.authorized, .provisional, .ephemeral].contains(reminders.authorization)
    }

    private var permissionLabel: String {
        switch reminders.authorization {
        case .authorized: String(localized: "reminders_permission_allowed")
        case .provisional, .ephemeral: String(localized: "reminders_permission_quiet")
        case .denied: String(localized: "reminders_permission_denied")
        default: String(localized: "reminders_permission_unknown")
        }
    }
}
