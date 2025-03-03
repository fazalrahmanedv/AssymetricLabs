import SwiftUI
struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var emoji: String
    var size: CGFloat
    var rotation: Angle
    var speed: CGFloat
    var rotationSpeed: Double
    var horizontalDrift: CGFloat
}

struct ConfettiAnimation: ViewModifier {
    @State private var confetti: [ConfettiPiece] = []
    let score: Int
    func body(content: Content) -> some View {
        ZStack {
            content
            GeometryReader { geometry in
                ZStack {
                    ForEach(confetti) { piece in
                        Text(piece.emoji)
                            .font(.system(size: piece.size))
                            .rotationEffect(piece.rotation)
                            .position(x: piece.x, y: piece.y)
                            .animation(.easeInOut(duration: 3.0), value: piece.y)  // Smooth animation
                    }
                }
                .onAppear {
                    generateConfetti(in: geometry.size)
                }
                .onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { _ in
                    moveConfetti(in: geometry.size)
                }
            }
        }
    }

    private func generateConfetti(in size: CGSize) {
        let emojis = confettiTypes(for: score)
        confetti = (1...30).map { _ in
            ConfettiPiece(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: -100...size.height / 2),
                emoji: emojis.randomElement() ?? "🎉",
                size: CGFloat.random(in: 20...40),
                rotation: .degrees(Double.random(in: 0...360)),
                speed: CGFloat.random(in: 2...5),
                rotationSpeed: Double.random(in: 10...30),
                horizontalDrift: CGFloat.random(in: -1.5...1.5)
            )
        }
    }

    private func moveConfetti(in size: CGSize) {
        for i in confetti.indices {
            withAnimation(.easeInOut(duration: 3.0)) {  // Smooth movement animation
                confetti[i].y += confetti[i].speed
                confetti[i].x += confetti[i].horizontalDrift
                confetti[i].rotation += .degrees(confetti[i].rotationSpeed / 10)

                // Reset when confetti falls out of view
                if confetti[i].y > size.height {
                    confetti[i].y = -50
                    confetti[i].x = CGFloat.random(in: 0...size.width)
                    confetti[i].rotation = .degrees(Double.random(in: 0...360))
                }
            }
        }
    }

    private func confettiTypes(for score: Int) -> [String] {
        switch score {
        case 4: return ["🎊"]
        case 5: return ["🎉"]
        default: return []
        }
    }
}

public extension View {
    func confettiEffect(score: Int) -> some View {
        self.modifier(ConfettiAnimation(score: score))
    }
}

