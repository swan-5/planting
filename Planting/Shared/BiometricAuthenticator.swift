import LocalAuthentication

/// PRODUCT_SPEC.md §17.4: Face ID, then Touch ID, then app passcode.
/// `.deviceOwnerAuthentication` lets iOS pick whichever of those is actually
/// available on the device, which is the native-API equivalent of that
/// preference order — there's no separate "try Face ID, then Touch ID" API.
enum BiometricAuthenticator {
    static func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }
}
