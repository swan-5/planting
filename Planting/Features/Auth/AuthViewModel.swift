import Foundation
import Observation
import FirebaseAuth

/// Phone-number sign-in, in two steps (send code, then verify it) —
/// mirrors the shape of this codebase's other `@Observable` view models
/// (e.g. `CategoryListViewModel`) owning their own loading/error state.
@Observable
final class AuthViewModel {
    private static let countryCode = "+82"

    var phoneNumber: String = ""
    var verificationCode: String = ""
    var isSendingCode = false
    var isVerifying = false
    var errorMessage: String?

    private(set) var verificationID: String?

    var isPhoneNumberValid: Bool {
        normalizedPhoneNumber.count >= 8
    }

    var isCodeValid: Bool {
        verificationCode.filter(\.isNumber).count == 6
    }

    private var normalizedPhoneNumber: String {
        let digits = phoneNumber.filter(\.isNumber)
        guard digits.hasPrefix("0") else { return digits }
        return String(digits.dropFirst())
    }

    private var e164PhoneNumber: String {
        Self.countryCode + normalizedPhoneNumber
    }

    @MainActor
    func sendVerificationCode() async -> Bool {
        errorMessage = nil
        isSendingCode = true
        defer { isSendingCode = false }
        do {
            verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(e164PhoneNumber, uiDelegate: nil)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    @MainActor
    func verifyCode() async -> Bool {
        guard let verificationID else {
            errorMessage = "Verification session expired. Request a new code."
            return false
        }
        errorMessage = nil
        isVerifying = true
        defer { isVerifying = false }
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )
        do {
            try await Auth.auth().signIn(with: credential)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
