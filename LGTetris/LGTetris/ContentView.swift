//
//  ContentView.swift
//  LGTetris
//
//  Created by Ethan Li on 2026/4/9.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var game = TetrisGame()
    @State private var selectedLevel = 1

    var body: some View {
        GeometryReader { proxy in
            let isCompactPortrait = proxy.size.width < 700 && proxy.size.height > proxy.size.width
            let portraitLeadingPadding: CGFloat = 20
            let portraitTrailingPadding: CGFloat = 28
            let compactSidebarWidth: CGFloat = 82
            let compactHorizontalSpacing: CGFloat = 12
            let compactHorizontalPadding: CGFloat = portraitLeadingPadding + portraitTrailingPadding
            let compactReservedHeight: CGFloat = 236
            let boardWidthFromHeight = max(
                150,
                (proxy.size.height - compactReservedHeight) * CGFloat(TetrisGame.columns) / CGFloat(TetrisGame.rows)
            )
            let boardWidth = isCompactPortrait
                ? min(
                    proxy.size.width - compactHorizontalPadding - compactSidebarWidth - compactHorizontalSpacing,
                    boardWidthFromHeight
                )
                : min(proxy.size.width * 0.62, 320)
            let cellSize = boardWidth / CGFloat(TetrisGame.columns)

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.07, blue: 0.14),
                        Color(red: 0.08, green: 0.15, blue: 0.24),
                        Color(red: 0.14, green: 0.08, blue: 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: isCompactPortrait ? 12 : 18) {
                    header

                    if isCompactPortrait {
                        HStack(alignment: .top, spacing: 12) {
                            board(cellSize: cellSize, compact: true)
                            compactSidebar(cellSize: cellSize)
                        }
                    } else {
                        HStack(alignment: .top, spacing: 16) {
                            board(cellSize: cellSize, compact: false)
                            sidePanel(cellSize: cellSize)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    controls(
                        compact: isCompactPortrait,
                        availableWidth: proxy.size.width - portraitLeadingPadding - portraitTrailingPadding
                    )
                }
                .padding(.leading, portraitLeadingPadding)
                .padding(.trailing, isCompactPortrait ? portraitTrailingPadding : 20)
                .padding(.vertical, isCompactPortrait ? 18 : 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private var header: some View {
        HStack {
            Spacer()
        }
        .frame(height: 0)
    }

    private var levelPicker: some View {
        Menu {
            ForEach(1...10, id: \.self) { level in
                Button("Lv \(level)") {
                    selectedLevel = level
                    game.setStartLevel(level)
                }
            }
        }
        label: {
            HStack(spacing: 6) {
                Text("Lv \(selectedLevel)")
                    .font(.subheadline.weight(.bold))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Color.white.opacity(0.12), in: Capsule())
        }
    }

    private func board(cellSize: CGFloat, compact: Bool) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<TetrisGame.rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<TetrisGame.columns, id: \.self) { column in
                        let tile = game.tileColor(row: row, column: column)

                        Rectangle()
                            .fill(tile.color)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.white.opacity(tile.isEmpty ? 0.05 : 0.12), lineWidth: 1)
                            )
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
        .background(Color.black.opacity(0.36))
        .overlay(
            Rectangle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 18, y: 10)
    }

    private func sidePanel(cellSize: CGFloat) -> some View {
        VStack(spacing: 14) {
            statCard(title: "Score", value: "\(game.score)")
            statCard(title: "Lines", value: "\(game.linesCleared)")
            statCard(title: "Level", value: "\(game.level)")

            VStack(alignment: .leading, spacing: 12) {
                Text("Next")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.88))

                nextPiecePreview(cellSize: min(cellSize * 0.8, 18))
                    .frame(maxWidth: .infinity, minHeight: 96)
                    .padding(12)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Controls")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.88))
                Text("Use the buttons to move, rotate, soft drop, or hard drop the falling piece.")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .frame(maxWidth: 170)
    }

    private func compactSidebar(cellSize: CGFloat) -> some View {
        VStack(spacing: 10) {
            compactTopControls
            compactNextCard(cellSize: cellSize)
            compactStatCard(title: "Score", value: "\(game.score)")
            compactStatCard(title: "Lines", value: "\(game.linesCleared)")
            compactStatCard(title: "Level", value: "\(game.level)")
            Spacer(minLength: 0)
        }
        .frame(width: 82)
    }

    private var compactTopControls: some View {
        VStack(spacing: 8) {
            levelPicker

            Button(game.isGameOver ? "Play Again" : "Restart") {
                game.setStartLevel(selectedLevel)
            }
            .font(.subheadline.weight(.bold))
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Color.white.opacity(0.12), in: Capsule())
            .foregroundStyle(.white)
        }
    }

    private func compactNextCard(cellSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.82))

            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.04))

                nextPiecePreview(cellSize: min(cellSize * 0.34, 8.5))
                    .frame(width: 42, height: 42)
            }
            .frame(width: 52, height: 52)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func compactStatCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Color.white.opacity(0.56))
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(Color.white.opacity(0.56))
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func nextPiecePreview(cellSize: CGFloat) -> some View {
        let layout = game.nextPreviewCells

        return GeometryReader { geometry in
            let spacing = max(1.5, cellSize * 0.22)
            let minX = layout.map(\.x).min() ?? 0
            let maxX = layout.map(\.x).max() ?? 0
            let minY = layout.map(\.y).min() ?? 0
            let maxY = layout.map(\.y).max() ?? 0
            let columns = maxX - minX + 1
            let rows = maxY - minY + 1
            let shapeWidth = CGFloat(columns) * cellSize + CGFloat(max(columns - 1, 0)) * spacing
            let shapeHeight = CGFloat(rows) * cellSize + CGFloat(max(rows - 1, 0)) * spacing
            let originX = (geometry.size.width - shapeWidth) / 2
            let originY = (geometry.size.height - shapeHeight) / 2

            ZStack {
                ForEach(Array(layout.enumerated()), id: \.offset) { _, point in
                    RoundedRectangle(cornerRadius: min(4, cellSize * 0.3), style: .continuous)
                        .fill(game.nextPiece.color)
                        .frame(width: cellSize, height: cellSize)
                        .position(
                            x: originX + CGFloat(point.x - minX) * (cellSize + spacing) + cellSize / 2,
                            y: originY + CGFloat(point.y - minY) * (cellSize + spacing) + cellSize / 2
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func controls(compact: Bool, availableWidth: CGFloat) -> some View {
        if compact {
            return AnyView(compactControls(availableWidth: availableWidth))
        }

        return AnyView(regularControls)
    }

    private var regularControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                repeatableControlButton(title: "Left", systemImage: "arrow.left") {
                    game.moveHorizontal(-1)
                }
                controlButton(title: "Rotate", systemImage: "rotate.right.fill") {
                    game.rotateClockwise()
                }
                repeatableControlButton(title: "Right", systemImage: "arrow.right") {
                    game.moveHorizontal(1)
                }
            }

            HStack(spacing: 12) {
                controlButton(title: "Soft Drop", systemImage: "arrow.down") {
                    game.softDrop()
                }
                controlButton(title: "Hard Drop", systemImage: "arrow.down.to.line") {
                    game.hardDrop()
                }
            }
        }
    }

    private func compactControls(availableWidth: CGFloat) -> some View {
        let outerPadding: CGFloat = 8
        let columnSpacing: CGFloat = 14
        let pauseWidth: CGFloat = 50
        let actionWidth: CGFloat = 88
        let actionButtonHeight: CGFloat = 74
        let horizontalInset: CGFloat = 4
        let controlHeight = max(170, actionButtonHeight * 2 + 22)
        let usableWidth = availableWidth - horizontalInset * 2 - outerPadding * 2
        let maxDirectionWidth = usableWidth - pauseWidth - actionWidth - columnSpacing * 2
        let directionColumnWidth = min(190, max(160, maxDirectionWidth))

        return HStack(alignment: .center, spacing: columnSpacing) {
            directionPad(width: directionColumnWidth, height: controlHeight)
                .frame(width: directionColumnWidth, height: controlHeight)

            actionPadButton(
                systemImage: game.isPaused ? "play.fill" : "pause.fill",
                width: pauseWidth
            ) {
                game.togglePause()
            }
            .frame(width: pauseWidth, height: controlHeight, alignment: .center)

            VStack(spacing: 0) {
                actionPadButton(systemImage: "rotate.right.fill", width: actionWidth, height: actionButtonHeight) {
                    game.rotateClockwise()
                }
                Spacer(minLength: 22)
                actionPadButton(systemImage: "arrow.down.to.line", width: actionWidth, height: actionButtonHeight) {
                    game.hardDrop()
                }
            }
            .frame(width: actionWidth, height: controlHeight)
        }
        .frame(width: usableWidth, alignment: .center)
        .padding(outerPadding)
        .padding(.horizontal, horizontalInset)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 6)
    }

    private func directionPad(width: CGFloat, height: CGFloat) -> some View {
        let buttonSize = min(64, max(52, min(width, height) * 0.34))
        let horizontalOffset = max(44, min(width * 0.33, 72))
        let verticalOffset = max(42, min(height * 0.34, 70))

        return ZStack {
            compactPadButton(systemImage: "arrow.up", size: buttonSize) {
                game.rotateClockwise()
            }
            .position(x: width / 2, y: height / 2 - verticalOffset)

            repeatableCompactPadButton(systemImage: "arrow.left", size: buttonSize) {
                game.moveHorizontal(-1)
            }
            .position(x: width / 2 - horizontalOffset, y: height / 2)

            repeatableCompactPadButton(systemImage: "arrow.right", size: buttonSize) {
                game.moveHorizontal(1)
            }
            .position(x: width / 2 + horizontalOffset, y: height / 2)

            holdPadButton(systemImage: "arrow.down", size: buttonSize)
                .position(x: width / 2, y: height / 2 + verticalOffset)
        }
        .frame(width: width, height: height)
    }

    private func controlButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .fontWeight(.bold)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .disabled(game.isGameOver || game.isPaused)
        .opacity((game.isGameOver || game.isPaused) ? 0.45 : 1)
    }

    private func holdPadButton(systemImage: String, size: CGFloat) -> some View {
        HoldablePadButton(
            systemImage: systemImage,
            size: size,
            isDisabled: game.isGameOver,
            onPress: { game.startSoftDrop() },
            onRelease: { game.stopSoftDrop() }
        )
    }

    private func repeatableControlButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        RepeatableControlButton(
            title: title,
            systemImage: systemImage,
            isDisabled: game.isGameOver || game.isPaused,
            action: action
        )
    }

    private func compactPadButton(systemImage: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .bold))
                .frame(width: size, height: size)
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .disabled(game.isGameOver)
        .opacity(game.isGameOver ? 0.45 : 1)
    }

    private func repeatableCompactPadButton(systemImage: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        RepeatablePadButton(
            systemImage: systemImage,
            size: size,
            isDisabled: game.isGameOver || game.isPaused,
            action: action
        )
    }

    private func actionPadButton(systemImage: String, width: CGFloat, height: CGFloat = 48, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
            .frame(width: width, height: height)
            .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(game.isGameOver)
        .opacity(game.isGameOver ? 0.45 : 1)
    }
}

private struct RepeatableControlButton: View {
    let title: String
    let systemImage: String
    let isDisabled: Bool
    let action: () -> Void

    @State private var isPressed = false
    @State private var repeatTask: Task<Void, Never>?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(title)
                .fontWeight(.bold)
        }
        .font(.headline)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .foregroundStyle(.white)
        .opacity(isDisabled ? 0.45 : (isPressed ? 0.72 : 1))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .gesture(repeatGesture)
        .onDisappear {
            stopRepeating()
        }
    }

    private var repeatGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !isDisabled, !isPressed else { return }
                isPressed = true
                startRepeating()
            }
            .onEnded { _ in
                stopRepeating()
            }
    }

    private func startRepeating() {
        action()
        repeatTask?.cancel()
        repeatTask = Task {
            try? await Task.sleep(nanoseconds: 180_000_000)
            while !Task.isCancelled {
                await MainActor.run {
                    action()
                }
                try? await Task.sleep(nanoseconds: 70_000_000)
            }
        }
    }

    private func stopRepeating() {
        isPressed = false
        repeatTask?.cancel()
        repeatTask = nil
    }
}

private struct HoldablePadButton: View {
    let systemImage: String
    let size: CGFloat
    let isDisabled: Bool
    let onPress: () -> Void
    let onRelease: () -> Void

    @State private var isPressed = false

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 20, weight: .bold))
            .frame(width: size, height: size)
            .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .foregroundStyle(.white)
            .opacity(isDisabled ? 0.45 : (isPressed ? 0.72 : 1))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isDisabled, !isPressed else { return }
                        isPressed = true
                        onPress()
                    }
                    .onEnded { _ in
                        guard isPressed else { return }
                        isPressed = false
                        onRelease()
                    }
            )
    }
}

private struct RepeatablePadButton: View {
    let systemImage: String
    let size: CGFloat
    let isDisabled: Bool
    let action: () -> Void

    @State private var isPressed = false
    @State private var repeatTask: Task<Void, Never>?

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 22, weight: .bold))
            .frame(width: size, height: size)
            .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .foregroundStyle(.white)
            .opacity(isDisabled ? 0.45 : (isPressed ? 0.72 : 1))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .gesture(repeatGesture)
            .onDisappear {
                stopRepeating()
            }
    }

    private var repeatGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !isDisabled, !isPressed else { return }
                isPressed = true
                startRepeating()
            }
            .onEnded { _ in
                stopRepeating()
            }
    }

    private func startRepeating() {
        action()
        repeatTask?.cancel()
        repeatTask = Task {
            try? await Task.sleep(nanoseconds: 180_000_000)
            while !Task.isCancelled {
                await MainActor.run {
                    action()
                }
                try? await Task.sleep(nanoseconds: 70_000_000)
            }
        }
    }

    private func stopRepeating() {
        isPressed = false
        repeatTask?.cancel()
        repeatTask = nil
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
