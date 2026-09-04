import SwiftUI

/// Pushed from PhoneLoginView after a code is sent. On success, AppSession's
/// Firebase auth-state listener flips `isSignedIn` and RootContainerView
/// swaps to RootTabView on its own — this screen doesn't navigate anywhere
/// itself on success.
struct VerificationCodeView: View {
    @Bindable var viewModel: AuthViewModel
    @State private var resendCooldown = 0

    private let resendCooldownSeconds = 30
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: PlantingSpacing.xl) {
            VStack(alignment: .leading, spacing: PlantingSpacing.xs) {
                Text("Enter code")
                    .font(PlantingFont.sectionHeading(22))
                    .foregroundStyle(PlantingColor.primaryText)
                Text("We sent a 6-digit code by text message.")
                    .font(PlantingFont.body())
                    .foregroundStyle(PlantingColor.secondaryText)
            }

            TextField("6-digit code", text: $viewModel.verificationCode)
                .font(PlantingFont.body())
                .keyboardType(.numberPad)
                .padding(.vertical, PlantingSpacing.sm)
                .padding(.horizontal, PlantingSpacing.md)
                .background(PlantingColor.divider.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: PlantingRadius.textField))

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(PlantingFont.caption)
                    .foregroundStyle(.red)
            }

            Button {
                Task { await viewModel.verifyCode() }
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isVerifying {
                        ProgressView()
                    } else {
                        Text("Verify")
                            .font(PlantingFont.emphasis())
                    }
                    Spacer()
                }
                .padding(.vertical, PlantingSpacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(PlantingColor.primaryBlue)
            .disabled(!viewModel.isCodeValid || viewModel.isVerifying)

            Button {
                Task {
                    if await viewModel.sendVerificationCode() {
                        resendCooldown = resendCooldownSeconds
                    }
                }
            } label: {
                Text(resendCooldown > 0 ? "Resend code (\(resendCooldown)s)" : "Resend code")
                    .font(PlantingFont.body(13))
                    .foregroundStyle(resendCooldown > 0 ? PlantingColor.secondaryText : PlantingColor.primaryBlue)
            }
            .disabled(resendCooldown > 0 || viewModel.isSendingCode)

            Spacer()
        }
        .padding(PlantingSpacing.lg)
        .background(PlantingColor.background)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { resendCooldown = resendCooldownSeconds }
        .onReceive(timer) { _ in
            if resendCooldown > 0 { resendCooldown -= 1 }
        }
    }
}
