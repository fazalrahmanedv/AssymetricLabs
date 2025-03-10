//
//  AudioPlayer.swift
//  QuizApp
//
//  Created by Admin on 10/03/25.
//

import AVFoundation
class AudioPlayer {
    static let shared = AudioPlayer()
    private var player: AVAudioPlayer?
    func playSound(forCorrectAnswer isCorrect: Bool) {
        let soundName = isCorrect ? "rightAnswer" : "wrongAnswer"
        if let soundURL = Bundle.main.url(forResource: soundName, withExtension: "wav") {
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
    func playSound(forWon hasWon: Bool) {
        let soundName = hasWon ? "won" : "lost"
        if let soundURL = Bundle.main.url(forResource: soundName, withExtension: "wav") {
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
}
