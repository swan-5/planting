import SwiftUI

/// Not in PRODUCT_SPEC.md — added on request. Root screen when signed out;
/// fixed to +82 rather than a country picker, since this is a single-market
/// hobby app for now.
struct PhoneLoginView: View {
    @State private var viewModel = AuthViewModel()
    @State private var isShowingVerification = false

    var body: some View {
        VStack(alignment: .leading, spacing: PlantingSpacing.xl) {
            VStack(alignment: .leading, spacing: PlantingSpacing.xs) {
                Text("Sign in")
                    .font(PlantingFont.sectionHeading(22))
                    .foregroundStyle(PlantingColor.primaryText)
                Text("Enter your phone number to continue.")
                    .font(PlantingFont.body())
                    .foregroundStyle(PlantingColor.secondaryText)
            }

            HStack(spacing: PlantingSpacing.sm) {
                Text("+82")
                    .font(PlantingFont.body())
                    .foregroundStyle(PlantingColor.secondaryText)
                    .padding(.vertical, PlantingSpacing.sm)
                    .padding(.horizontal, PlantingSpacing.md)
                    .background(PlantingColor.divider.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: PlantingRadius.textField))

                TextField("Phone number", text: $viewModel.phoneNumber)
                    .font(PlantingFont.body())
                    .keyboardType(.phonePad)
                    .padding(.vertical, PlantingSpacing.sm)
                    .padding(.horizontal, PlantingSpacing.md)
                    .background(PlantingColor.divider.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: PlantingRadius.textField))
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(PlantingFont.caption)
                    .foregroundStyle(.red)
            }

            Button {
                Task {
                    if await viewModel.sendVerificationCode() {
                        isShowingVerification = true
                    }
                }
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isSendingCode {
                        ProgressView()
                    } else {
                        Text("Send code")
                            .font(PlantingFont.emphasis())
                    }
                    Spacer()
                }
                .padding(.vertical, PlantingSpacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(PlantingColor.primaryBlue)
            .disabled(!viewModel.isPhoneNumberValid || viewModel.isSendingCode)

            Spacer()
        }
        .padding(PlantingSpacing.lg)
        .background(PlantingColor.background)
        .navigationDestination(isPresented: $isShowingVerification) {
            VerificationCodeView(viewModel: viewModel)
        }
    }
}
