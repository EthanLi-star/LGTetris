//
//  TetrisSoundPlayer.swift
//  LGTetris
//
//  Created by Ethan Li on 2026/4/9.
//

import AVFoundation
import Foundation

@MainActor
final class TetrisSoundPlayer {
    static let shared = TetrisSoundPlayer()

    enum Effect: String, CaseIterable {
        case move
        case rotate
        case lock
        case clear
        case hardDrop
        case pause
        case gameOver
    }

    private var players: [Effect: AVAudioPlayer] = [:]

    private init() {
        preparePlayers()
    }

    func play(_ effect: Effect) {
        guard let player = players[effect] else { return }
        player.currentTime = 0
        player.play()
    }

    private func preparePlayers() {
        for effect in Effect.allCases {
            guard let fileURL = soundURL(for: effect) else { continue }

            do {
                let player = try AVAudioPlayer(contentsOf: fileURL)
                player.volume = 0.34
                player.prepareToPlay()
                players[effect] = player
            } catch {
                continue
            }
        }
    }

    private func soundURL(for effect: Effect) -> URL? {
        for fileExtension in ["aiff", "wav", "caf", "mp3", "m4a"] {
            if let url = Bundle.main.url(forResource: effect.rawValue, withExtension: fileExtension, subdirectory: "Sounds") {
                return url
            }

            if let url = Bundle.main.url(forResource: effect.rawValue, withExtension: fileExtension) {
                return url
            }
        }

        return nil
    }
}
