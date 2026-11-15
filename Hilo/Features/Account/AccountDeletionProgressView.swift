import SwiftUI

struct AccountDeletionProgressView: View {
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
                    .tint(AppColors.accent)
                    .accessibilityLabel("account_delete_working")

                VStack(spacing: 8) {
                    Text("account_delete_farewell")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(AppColors.titles)
                    Text("account_delete_working")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
