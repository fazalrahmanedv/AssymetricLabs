import SwiftUI

struct HTMLTextView: View {
    let htmlContent: String
    @Environment(\.sizeCategory) var sizeCategory  // Triggers update on dynamic type changes
    
    var body: some View {
        if #available(iOS 15.0, *) {
            // ✅ iOS 15+ - Use AttributedString directly
            if let attributedString = AttributedString(html: htmlContent) {
                Text(attributedString)
                    .padding()
            } else {
                Text("Unable to load content.")
            }
        } else {
            // ✅ iOS 14 Fallback - Use NSAttributedString with Text
            if let attributedString = NSAttributedString(html: htmlContent) {
                Text(attributedString.toPlainText())
                    .padding()
            } else {
                Text("Unable to load content.")
            }
        }
    }
}

// ✅ Preview
struct HTMLTextView_Previews: PreviewProvider {
    static var previews: some View {
        HTMLTextView(htmlContent: "<b>Sample HTML Content</b><br><i>With dynamic scaling!</i>")
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

// MARK: - iOS 15+ AttributedString Extension
@available(iOS 15.0, *)
extension AttributedString {
    init?(html: String) {
        guard let data = html.data(using: .utf8) else { return nil }
        guard let mutableNSAttrString = try? NSMutableAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        ) else { return nil }
        
        // ✅ Apply dynamic type and color correction
        mutableNSAttrString.applyDynamicTypeAndColorCorrection()
        self.init(mutableNSAttrString)
    }
}

// MARK: - iOS 14 NSAttributedString Fallback
extension NSAttributedString {
    convenience init?(html: String) {
        guard let data = html.data(using: .utf8) else { return nil }
        try? self.init(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
    }
    
    /// Converts NSAttributedString to plain String for SwiftUI
    func toPlainText() -> String {
        return string
    }
}

// MARK: - Dynamic Type & Color Correction
extension NSMutableAttributedString {
    /// Iterates over each attribute range and applies the following:
    /// - Converts fonts to system fonts, preserving bold/italic traits.
    /// - Applies dynamic scaling using `.body` as the reference style.
    /// - Corrects foreground colors, replacing default black with `UIColor.label`.
    func applyDynamicTypeAndColorCorrection() {
        let fullRange = NSRange(location: 0, length: self.length)
        
        self.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
            // --- Font Transformation & Dynamic Scaling ---
            if let font = attributes[.font] as? UIFont {
                var newFont: UIFont
                let traits = font.fontDescriptor.symbolicTraits
                
                // Preserve Bold & Italic Traits
                if traits.contains(.traitBold) && traits.contains(.traitItalic) {
                    newFont = UIFont(descriptor: font.fontDescriptor.withSymbolicTraits([.traitBold, .traitItalic])!, size: font.pointSize)
                } else if traits.contains(.traitBold) {
                    newFont = UIFont.boldSystemFont(ofSize: font.pointSize)
                } else if traits.contains(.traitItalic) {
                    newFont = UIFont.italicSystemFont(ofSize: font.pointSize)
                } else {
                    newFont = UIFont.systemFont(ofSize: font.pointSize)
                }
                
                // Scale font dynamically using `.body`
                newFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: newFont)
                self.addAttribute(.font, value: newFont, range: range)
            } else {
                // Assign preferred font if no font attribute is provided
                let newFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body))
                self.addAttribute(.font, value: newFont, range: range)
            }
            
            // --- Foreground Color Correction ---
            if let fgColor = attributes[.foregroundColor] as? UIColor {
                // Get RGB components to check if the color is nearly black
                var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                if fgColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha), red < 0.01, green < 0.01, blue < 0.01 {
                    // Replace black with dynamic UIColor.label
                    self.addAttribute(.foregroundColor, value: UIColor.label, range: range)
                }
            } else {
                // Assign dynamic foreground color if not present
                self.addAttribute(.foregroundColor, value: UIColor.label, range: range)
            }
        }
    }
}
