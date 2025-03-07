import SwiftUI

// Custom view that smoothly animates the score from 0 to 100,
// while clamping the displayed value to ensure it never exceeds 100.
struct AnimatedNumberText: View, Animatable {
    var value: Double
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    var body: some View {
        // Clamp the value to 100 before converting to an integer
        Text("+\(Int(min(value, 100)))")
            .font(.system(size: 40, weight: .bold))
            .foregroundColor(.white)
    }
}

struct FeedbackView: View {
    @State private var animate = false
    @State private var score: Double = 0
    @State private var gradientRotation: Double = 0
    
    var body: some View {
        ZStack {
            // Rotating gradient background for extra visual interest
            AngularGradient(
                gradient: Gradient(colors: [.blue, .purple, .blue]),
                center: .center,
                angle: .degrees(gradientRotation)
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(Animation.linear(duration: 10).repeatForever(autoreverses: false)) {
                    gradientRotation = 360
                }
            }
            
            // Semi-transparent overlay to ensure foreground elements pop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Celebratory "Awesome!" text with a spring animation for a natural pop
                Text("Awesome!")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.yellow)
                    .scaleEffect(animate ? 1.2 : 0.8)
                    .opacity(animate ? 1.0 : 0.0)
                    .onAppear {
                        withAnimation(
                            Animation.interpolatingSpring(stiffness: 100, damping: 10)
                                .repeatCount(2, autoreverses: true)
                        ) {
                            animate = true
                        }
                    }
                
                // Animated score text that counts from 0 to 100,
                // with clamping in the view to avoid overshooting.
                AnimatedNumberText(value: score)
                    .onAppear {
                        withAnimation(
                            Animation.interpolatingSpring(stiffness: 100, damping: 20).delay(0.5)
                        ) {
                            score = 100
                        }
                    }
            }
        }
    }
}

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackView()
    }
}
