import SwiftUI

struct HTMLTextView: View {
    let htmlContent: String
    @Environment(\.sizeCategory) var sizeCategory  // Triggers update on dynamic type changes
    
    var body: some View {
        // Recreate the AttributedString when the sizeCategory changes.
        if let attributedString = AttributedString(html: htmlContent) {
            Text(attributedString)
                .padding()
        } else {
            Text("Unable to load content.")
        }
    }
}

struct HTMLTextView_Previews: PreviewProvider {
    static var previews: some View {
        HTMLTextView(htmlContent: "<b>Sample HTML Content</b>")
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

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
        
        // Apply dynamic type scaling and color correction.
        mutableNSAttrString.applyDynamicTypeAndColorCorrection()
        self.init(mutableNSAttrString)
    }
}

extension NSMutableAttributedString {
    /// Iterates over each attribute range and does the following:
    /// - If a font is provided, it converts it to a system font (preserving bold/italic traits)
    ///   and applies dynamic scaling using .body as the reference style.
    /// - If no font is provided, it assigns UIFont.preferredFont(forTextStyle: .body).
    /// - For the foreground color, if the color is nearly black (default) it replaces it with UIColor.label.
    func applyDynamicTypeAndColorCorrection() {
        let fullRange = NSRange(location: 0, length: self.length)
        
        self.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
            // --- Font Transformation & Dynamic Scaling ---
            if let font = attributes[.font] as? UIFont {
                var newFont: UIFont
                let traits = font.fontDescriptor.symbolicTraits
                if traits.contains(.traitBold) && traits.contains(.traitItalic) {
                    if let descriptor = font.fontDescriptor.withSymbolicTraits([.traitBold, .traitItalic]) {
                        newFont = UIFont(descriptor: descriptor, size: font.pointSize)
                    } else {
                        newFont = UIFont.boldSystemFont(ofSize: font.pointSize)
                    }
                } else if traits.contains(.traitBold) {
                    newFont = UIFont.boldSystemFont(ofSize: font.pointSize)
                } else if traits.contains(.traitItalic) {
                    newFont = UIFont.italicSystemFont(ofSize: font.pointSize)
                } else {
                    newFont = UIFont.systemFont(ofSize: font.pointSize)
                }
                // Scale the font for Dynamic Type using .body as the reference.
                newFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: newFont)
                self.addAttribute(.font, value: newFont, range: range)
            } else {
                // If no font is provided, use the preferred font for .body.
                let newFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body))
                self.addAttribute(.font, value: newFont, range: range)
            }
            
            // --- Foreground Color Correction ---
            if let fgColor = attributes[.foregroundColor] as? UIColor {
                // Get RGB components.
                var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                if fgColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
                    // If the color is nearly black (default), override it with dynamic UIColor.label.
                    if red < 0.01 && green < 0.01 && blue < 0.01 {
                        self.addAttribute(.foregroundColor, value: UIColor.label, range: range)
                    }
                }
            } else {
                // If no foreground color is provided, assign a dynamic color.
                self.addAttribute(.foregroundColor, value: UIColor.label, range: range)
            }
        }
    }
}
