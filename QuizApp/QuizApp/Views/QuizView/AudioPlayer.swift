//
//  AudioPlayer.swift
//  QuizApp
//
//  Created by Admin on 10/03/25.
//
import AVFoundation
import UIKit
class AudioPlayer {
    static let shared = AudioPlayer()
    private var player: AVAudioPlayer?
    private var timerPlayer: AVAudioPlayer?
    private var countdownTimer: Timer?
    private var remainingTime: Int = 0
    // ✅ MARK: - Public Methods
    /// Automatically plays correct or wrong answer sound + Haptic
    func playSound(forCorrectAnswer isCorrect: Bool) {
        let soundName = isCorrect ? "rightAnswer" : "wrongAnswer"
        playSound(named: soundName, format: "wav")
        
        if isCorrect {
            triggerHaptic(style: .success)
        } else {
            triggerHaptic(style: .error)
        }
    }
    /// Automatically plays sound when user wins or loses + Haptic
    func playSound(forWon hasWon: Bool) {
        let soundName = hasWon ? "won" : "lost"
        playSound(named: soundName, format: "wav")
        
        if hasWon {
            triggerHaptic(style: .success)
        } else {
            triggerHaptic(style: .error)
        }
    }
    /// Starts the timer sound with automatic ticking and timeout alert + Haptic
    func playTimeout() {
       self.playSound(named: "timeout", format: "mp3")
        self.triggerHaptic(style: .warning)
    }
    /// Stops all sounds when the question is answered, skipped, or time runs out
    deinit {
        stopAllSounds()
    }
    func stopAllSounds() {
        player?.stop()
        player = nil
        timerPlayer?.stop()
        timerPlayer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    /// Stops only the timer sound (useful when the user moves to the next question)
    func stopTimerSound() {
        timerPlayer?.stop()
    }
    // ✅ MARK: - Private Sound Logic
    private func playSound(named soundName: String,  format: String) {
        if let soundURL = Bundle.main.url(forResource: soundName, withExtension: format) {
            do {
                player = try AVAudioPlayer(contentsOf: soundURL)
                player?.play()
            } catch {
                print("Failed to play sound: \(error)")
            }
        } else {
            print("Failed to load sound")
        }
    }
    func playLoopingSound(named soundName: String, format: String) {
        if let soundURL = Bundle.main.url(forResource: soundName, withExtension: format) {
            do {
                timerPlayer = try AVAudioPlayer(contentsOf: soundURL)
                timerPlayer?.numberOfLoops = -1 // Infinite loop until stopped
                timerPlayer?.play()
            } catch {
                print("Failed to play sound: \(error)")
            }
        } else {
            print("Failed to load sound")
        }
    }
    // ✅ MARK: - Haptic Feedback Logic
    private func triggerHaptic(style: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(style)
    }
    /// Provides a light click feedback when navigating to the next question
    func triggerClickHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
