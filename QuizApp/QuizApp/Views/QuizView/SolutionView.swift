import SwiftUI
import QuizRepo
struct SolutionView: View {
    let solution: QuizSolution?
    let width: CGFloat
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Solution")
                .font(.subheadline)
                .padding(.horizontal, 8)
            if let solution = solution {
                // You can add a header showing if the answer was correct if desired.
                // For now, we just display the solution content.
                Group {
                    if solution.contentType == "image" {
                        // Try to load the image from cache; data is offline so this should work.
                        if let image = ImageCache.shared.image(forKey: solution.contentData ?? "") {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: width)
                        } else {
                            // Fallback view while image is being loaded.
                            ProgressView()
                                .frame(width: width, height: 200)
                        }
                    } else if solution.contentType == "htmlText" {
                        // Use your existing HTMLTextView to display HTML content.
                        HTMLTextView(htmlContent: solution.contentData ?? "")
                            .frame(maxWidth: width)
                    } else {
                        // Default to displaying plain text.
                        ScrollView {
                            Text(solution.contentData ?? "")
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, 8)
            } else {
                // In case there's no solution object.
                ScrollView {
                    Text("No solution available.")
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(width: width)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
