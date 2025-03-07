import SwiftUI

struct CachedImageView: View {
    let urlString: String
    var body: some View {
        if let cachedImage = ImageCache.shared.image(forKey: urlString) {
            Image(uiImage: cachedImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            ProgressView()
                .frame(width: 200, height: 200)
        }
    }
}
struct CachedImageView_Previews: PreviewProvider {
    static var previews: some View {
        CachedImageView(urlString: "https://example.com/sample-image.jpg")
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
