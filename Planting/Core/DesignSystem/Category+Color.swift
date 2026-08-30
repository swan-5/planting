import SwiftUI

extension Color {
    /// Accepts hex strings with or without a leading "#".
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard let value = UInt32(hex, radix: 16) else {
            self = PlantingColor.secondaryText
            return
        }
        self.init(hex: value)
    }
}

extension Category {
    var color: Color {
        Color(hexString: colorHex)
    }
}
