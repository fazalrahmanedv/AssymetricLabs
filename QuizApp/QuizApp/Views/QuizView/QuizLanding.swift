import SwiftUI
struct QuizLandingPage: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var animatePulse = false
      var backgroundGradient: LinearGradient {
          if colorScheme == .dark {
              return  LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 14/255, green: 28/255, blue: 38/255),
                    Color(red: 42/255, green: 69/255, blue: 75/255),
                    Color(red: 41/255, green: 72/255, blue: 97/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
          } else {
             return  LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 202/255, green: 208/255, blue: 255/255),
                    Color(red: 224/255, green: 230/255, blue: 255/255),
                    Color(red: 227/255, green: 227/255, blue: 227/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
          }
      }
    var body: some View {
        ZStack {
            backgroundGradient
            .ignoresSafeArea()
            VStack {
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("5 MCQs")
                            .font(.headline)
                        Text("Questions")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.quaternarySystemFill))
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Unlimited")
                            .font(.headline)
                        Text("Attempts")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.quaternarySystemFill))
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("5 minutes")
                            .font(.headline)
                        Text("Total time")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.quaternarySystemFill))
                    .cornerRadius(8)
                }
                Spacer()
                VStack {
                    Text("You have 5 minutes to complete this Quiz")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                    Text("All the best")
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                Spacer()
                VStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }) {
                        HStack(spacing: 4) {
                            Text("Continue")
                            if #available(iOS 17.0, *) {
                                Image(systemName: "arrow.right")
                                    .symbolEffect(.pulse, options: .repeating, isActive: animatePulse)
                            } else {
                                // Fallback on earlier versions
                            }
                        } .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Text("Tap continue when you are ready to take the quiz")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .frame(maxHeight: .infinity)
        }
        .onAppear{
            animatePulse = true
        }
    }
}

struct QuizLandingPage_Previews: PreviewProvider {
    static var previews: some View {
        QuizLandingPage()
            .previewLayout(.sizeThatFits)
    }
}
