import SwiftUI
struct BookmarkButton: View {
    let isBookmarked: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .foregroundColor(isBookmarked ? .yellow : .gray)
                .font(.title3)
        }
    }
}
struct BookmarkButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BookmarkButton(isBookmarked: true, action: {
                print("Bookmark tapped (bookmarked)")
            })
            .previewLayout(.sizeThatFits)
            .padding()
            
            BookmarkButton(isBookmarked: false, action: {
                print("Bookmark tapped (not bookmarked)")
            })
            .previewLayout(.sizeThatFits)
            .padding()
        }
    }
}
