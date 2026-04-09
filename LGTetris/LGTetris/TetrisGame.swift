//
//  TetrisGame.swift
//  LGTetris
//
//  Created by Ethan Li on 2026/4/9.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class TetrisGame: NSObject, ObservableObject {
    static let columns = 10
    static let rows = 20

    @Published private(set) var score = 0
    @Published private(set) var level = 1
    @Published private(set) var linesCleared = 0
    @Published private(set) var isGameOver = false
    @Published private(set) var isPaused = false
    @Published private(set) var nextPiece: Tetromino = Tetromino(kind: .t)

    private var isSoftDropping = false
    private var startLevel = 1
    private var board = Array(
        repeating: Array(repeating: Tile.empty, count: columns),
        count: rows
    )
    private var activePiece = ActivePiece.initial(kind: .i)
    private var timer: Timer?
    private var bag: [Tetromino.Kind] = []
    private let soundPlayer = TetrisSoundPlayer.shared

    override init() {
        super.init()
        restart()
    }

    deinit {
        timer?.invalidate()
    }

    func restart() {
        timer?.invalidate()
        board = Array(repeating: Array(repeating: Tile.empty, count: Self.columns), count: Self.rows)
        score = 0
        level = startLevel
        linesCleared = 0
        isGameOver = false
        isPaused = false
        isSoftDropping = false
        bag = []
        nextPiece = Tetromino(kind: drawKind())
        spawnPiece()
        startTimer()
    }

    func setStartLevel(_ newLevel: Int) {
        let clamped = min(max(newLevel, 1), 10)
        startLevel = clamped
        restart()
    }

    func togglePause() {
        guard !isGameOver else { return }
        isPaused.toggle()
        soundPlayer.play(.pause)
        if isPaused {
            timer?.invalidate()
        } else {
            restartTimer()
        }
    }

    func moveHorizontal(_ delta: Int) {
        guard !isGameOver, !isPaused else { return }
        if attemptMove(byX: delta, y: 0) {
            soundPlayer.play(.move)
        }
    }

    func softDrop() {
        guard !isGameOver, !isPaused else { return }
        if !attemptMove(byX: 0, y: 1) {
            lockPiece()
        } else {
            score += 1
        }
    }

    func startSoftDrop() {
        guard !isGameOver, !isPaused, !isSoftDropping else { return }
        isSoftDropping = true
        restartTimer()
    }

    func stopSoftDrop() {
        guard isSoftDropping else { return }
        isSoftDropping = false
        restartTimer()
    }

    func hardDrop() {
        guard !isGameOver, !isPaused else { return }
        var dropDistance = 0

        while attemptMove(byX: 0, y: 1) {
            dropDistance += 1
        }

        score += dropDistance * 2
        soundPlayer.play(.hardDrop)
        lockPiece()
    }

    func rotateClockwise() {
        guard !isGameOver, !isPaused else { return }
        let rotated = activePiece.rotatedClockwise()

        for kick in [0, -1, 1, -2, 2] {
            let candidate = rotated.shiftedBy(x: kick, y: 0)
            if canPlace(candidate) {
                activePiece = candidate
                objectWillChange.send()
                soundPlayer.play(.rotate)
                return
            }
        }
    }

    func tileColor(row: Int, column: Int) -> (color: Color, isEmpty: Bool) {
        for point in activePiece.points where point.y == row && point.x == column {
            return (activePiece.kind.color, false)
        }

        let tile = board[row][column]
        return (tile.color ?? .clear, tile.isEmpty)
    }

    var nextPreviewCells: [Point] {
        let points = nextPiece.rotationPoints[0]
        guard
            let minX = points.map(\.x).min(),
            let minY = points.map(\.y).min()
        else {
            return []
        }

        let xOffset = nextPiece.kind == .i ? 0 : 1
        return points.map { Point(x: $0.x - minX + xOffset, y: $0.y - minY + 1) }
    }

    private func startTimer() {
        let interval = isSoftDropping ? 0.05 : max(0.14, 0.7 - Double(level - 1) * 0.06)
        timer = Timer.scheduledTimer(
            timeInterval: interval,
            target: self,
            selector: #selector(handleTimerTick),
            userInfo: nil,
            repeats: true
        )
    }

    @objc private func handleTimerTick() {
        tick()
    }

    private func tick() {
        guard !isGameOver, !isPaused else { return }
        if !attemptMove(byX: 0, y: 1) {
            lockPiece()
        }
    }

    private func restartTimer() {
        timer?.invalidate()
        startTimer()
    }

    private func spawnPiece() {
        let currentKind = nextPiece.kind
        nextPiece = Tetromino(kind: drawKind())
        activePiece = ActivePiece.initial(kind: currentKind)

        if !canPlace(activePiece) {
            isGameOver = true
            timer?.invalidate()
            soundPlayer.play(.gameOver)
        }

        objectWillChange.send()
    }

    @discardableResult
    private func attemptMove(byX deltaX: Int, y deltaY: Int) -> Bool {
        let candidate = activePiece.shiftedBy(x: deltaX, y: deltaY)
        guard canPlace(candidate) else { return false }
        activePiece = candidate
        objectWillChange.send()
        return true
    }

    private func canPlace(_ piece: ActivePiece) -> Bool {
        for point in piece.points {
            guard point.x >= 0, point.x < Self.columns, point.y < Self.rows else {
                return false
            }

            if point.y >= 0, !board[point.y][point.x].isEmpty {
                return false
            }
        }

        return true
    }

    private func lockPiece() {
        for point in activePiece.points where point.y >= 0 && point.y < Self.rows {
            board[point.y][point.x] = Tile(color: activePiece.kind.color)
        }

        let clearedLines = clearLines()
        if clearedLines == 0 {
            soundPlayer.play(.lock)
        }
        spawnPiece()
    }

    @discardableResult
    private func clearLines() -> Int {
        let clearedRows = board.indices.filter { row in
            board[row].allSatisfy { !$0.isEmpty }
        }

        guard !clearedRows.isEmpty else { return 0 }

        let remainingRows = board.enumerated()
            .filter { !clearedRows.contains($0.offset) }
            .map(\.element)

        let emptyRow = Array(repeating: Tile.empty, count: Self.columns)
        board = Array(repeating: emptyRow, count: clearedRows.count) + remainingRows

        linesCleared += clearedRows.count
        level = startLevel + (linesCleared / 10)

        let points: [Int: Int] = [1: 100, 2: 300, 3: 500, 4: 800]
        score += (points[clearedRows.count] ?? 0) * level

        soundPlayer.play(.clear)
        restartTimer()
        return clearedRows.count
    }

    private func drawKind() -> Tetromino.Kind {
        if bag.isEmpty {
            bag = Tetromino.Kind.allCases.shuffled()
        }
        return bag.removeFirst()
    }
}

struct Tile {
    let color: Color?

    var isEmpty: Bool {
        color == nil
    }

    static let empty = Tile(color: nil)
}

struct Point: Hashable {
    let x: Int
    let y: Int
}

struct Tetromino {
    enum Kind: CaseIterable {
        case i
        case o
        case t
        case s
        case z
        case j
        case l

        var color: Color {
            switch self {
            case .i: return Color(red: 0.32, green: 0.89, blue: 0.95)
            case .o: return Color(red: 0.98, green: 0.84, blue: 0.32)
            case .t: return Color(red: 0.73, green: 0.43, blue: 0.98)
            case .s: return Color(red: 0.44, green: 0.9, blue: 0.51)
            case .z: return Color(red: 0.98, green: 0.41, blue: 0.48)
            case .j: return Color(red: 0.4, green: 0.58, blue: 0.97)
            case .l: return Color(red: 0.98, green: 0.61, blue: 0.3)
            }
        }

        var rotations: [[Point]] {
            switch self {
            case .i:
                return [
                    [Point(x: 2, y: 0), Point(x: 2, y: 1), Point(x: 2, y: 2), Point(x: 2, y: 3)],
                    [Point(x: 0, y: 2), Point(x: 1, y: 2), Point(x: 2, y: 2), Point(x: 3, y: 2)],
                    [Point(x: 1, y: 0), Point(x: 1, y: 1), Point(x: 1, y: 2), Point(x: 1, y: 3)],
                    [Point(x: 0, y: 1), Point(x: 1, y: 1), Point(x: 2, y: 1), Point(x: 3, y: 1)]
                ]
            case .o:
                let square = [Point(x: 1, y: 0), Point(x: 2, y: 0), Point(x: 1, y: 1), Point(x: 2, y: 1)]
                return [square, square, square, square]
            case .t:
                return [
                    [Point(x: 1, y: 0), Point(x: 0, y: 1), Point(x: 1, y: 1), Point(x: 2, y: 1)],
                    [Point(x: 1, y: 0), Point(x: 1, y: 1), Point(x: 2, y: 1), Point(x: 1, y: 2)],
                    [Point(x: 0, y: 1), Point(x: 1, y: 1), Point(x: 2, y: 1), Point(x: 1, y: 2)],
                    [Point(x: 1, y: 0), Point(x: 0, y: 1), Point(x: 1, y: 1), Point(x: 1, y: 2)]
                ]
            case .s:
                return [
                    [Point(x: 1, y: 0), Point(x: 2, y: 0), Point(x: 0, y: 1), Point(x: 1, y: 1)],
                    [Point(x: 1, y: 0), Point(x: 1, y: 1), Point(x: 2, y: 1), Point(x: 2, y: 2)],
                    [Point(x: 1, y: 1), Point(x: 2, y: 1), Point(x: 0, y: 2), Point(x: 1, y: 2)],
                    [Point(x: 0, y: 0), Point(x: 0, y: 1), Point(x: 1, y: 1), Point(x: 1, y: 2)]
                ]
            case .z:
                return [
                    [Point(x: 0, y: 0), Point(x: 1, y: 0), Point(x: 1, y: 1), Point(x: 2, y: 1)],
                    [Point(x: 2, y: 0), Point(x: 1, y: 1), Point(x: 2, y: 1), Point(x: 1, y: 2)],
                    [Point(x: 0, y: 1), Point(x: 1, y: 1), Point(x: 1, y: 2), Point(x: 2, y: 2)],
                    [Point(x: 1, y: 0), Point(x: 0, y: 1), Point(x: 1, y: 1), Point(x: 0, y: 2)]
                ]
            case .j:
                return [
                    [Point(x: 0, y: 0), Point(x: 0, y: 1), Point(x: 1, y: 1), Point(x: 2, y: 1)],
                    [Point(x: 1, y: 0), Point(x: 2, y: 0), Point(x: 1, y: 1), Point(x: 1, y: 2)],
                    [Point(x: 0, y: 1), Point(x: 1, y: 1), Point(x: 2, y: 1), Point(x: 2, y: 2)],
                    [Point(x: 1, y: 0), Point(x: 1, y: 1), Point(x: 0, y: 2), Point(x: 1, y: 2)]
                ]
            case .l:
                return [
                    [Point(x: 2, y: 0), Point(x: 0, y: 1), Point(x: 1, y: 1), Point(x: 2, y: 1)],
                    [Point(x: 1, y: 0), Point(x: 1, y: 1), Point(x: 1, y: 2), Point(x: 2, y: 2)],
                    [Point(x: 0, y: 1), Point(x: 1, y: 1), Point(x: 2, y: 1), Point(x: 0, y: 2)],
                    [Point(x: 0, y: 0), Point(x: 1, y: 0), Point(x: 1, y: 1), Point(x: 1, y: 2)]
                ]
            }
        }
    }

    let kind: Kind

    var color: Color {
        kind.color
    }

    var rotationPoints: [[Point]] {
        kind.rotations
    }
}

struct ActivePiece {
    let kind: Tetromino.Kind
    let rotation: Int
    let origin: Point

    static func initial(kind: Tetromino.Kind) -> ActivePiece {
        ActivePiece(kind: kind, rotation: 0, origin: Point(x: 3, y: -1))
    }

    var points: [Point] {
        kind.rotations[rotation].map { point in
            Point(x: origin.x + point.x, y: origin.y + point.y)
        }
    }

    func shiftedBy(x: Int, y: Int) -> ActivePiece {
        ActivePiece(kind: kind, rotation: rotation, origin: Point(x: origin.x + x, y: origin.y + y))
    }

    func rotatedClockwise() -> ActivePiece {
        ActivePiece(kind: kind, rotation: (rotation + 1) % 4, origin: origin)
    }
}
