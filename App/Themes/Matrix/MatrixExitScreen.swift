//
//  MatrixExitScreen.swift
//  HAL
//
//  Déconnexion de la Matrice. Pluie de code verte qui envahit tout l'écran
//  avant d'afficher "WAKE UP, NEO.".
//
import AppKit

final class MatrixRainView: NSView {

    private var animationTask: Task<Void, Never>?
    private var startTime = Date()

    private let font = NSFont(name: "Menlo", size: 14) ?? NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    private let columnWidth: CGFloat = 14

    private struct Column {
        var chars: [Character]
        var originY: CGFloat
        var speed: CGFloat
        var age: Int
    }

    private var columns: [Column] = []

    private let glyphs: [Character] = Array(
        "ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ:・.\"=*+-<>|"
    )

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupColumns()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    private func setupColumns() {
        columns.removeAll()
        let count = Int(bounds.width / columnWidth) + 3
        for _ in stride(from: 0, to: count, by: 1) where Double.random(in: 0...1) > 0.25 {
            let length = Int.random(in: 16...38)
            var chars: [Character] = []
            for _ in 0..<length {
                chars.append(glyphs.randomElement() ?? "0")
            }
            columns.append(Column(
                chars: chars,
                originY: CGFloat.random(in: bounds.height + 40 ... bounds.height + 400),
                speed: CGFloat.random(in: 14.0 ... 22.0),
                age: 0
            ))
        }
    }

    func start(completion: @escaping () -> Void) {
        startTime = Date()

        animationTask = Task { @MainActor in
            let tickNanoseconds = UInt64((1.0 / 30.0) * 1_000_000_000)
            let totalDuration = 4.8

            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed > totalDuration {
                    break
                }
                update()
                needsDisplay = true
                try? await Task.sleep(nanoseconds: tickNanoseconds)
            }

            // Final frame
            needsDisplay = true
            completion()
        }
    }

    func stop() {
        animationTask?.cancel()
        animationTask = nil
    }

    private func update() {
        for columnIndex in columns.indices {
            columns[columnIndex].originY -= columns[columnIndex].speed
            columns[columnIndex].age += 1
            if columns[columnIndex].age % 6 == 0 {
                let glyphIndex = Int.random(in: 0..<columns[columnIndex].chars.count)
                columns[columnIndex].chars[glyphIndex] = glyphs.randomElement() ?? "0"
            }
            if columns[columnIndex].originY < -CGFloat(columns[columnIndex].chars.count) * 18 {
                let length = Int.random(in: 16...38)
                var chars: [Character] = []
                for _ in 0..<length {
                    chars.append(glyphs.randomElement() ?? "0")
                }
                columns[columnIndex] = Column(
                    chars: chars,
                    originY: CGFloat.random(in: bounds.height + 40 ... bounds.height + 400),
                    speed: CGFloat.random(in: 14.0 ... 22.0),
                    age: 0
                )
            }
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        bounds.fill()

        for columnIndex in columns.indices {
            let columnX = CGFloat(columnIndex) * columnWidth
            for rowOffset in columns[columnIndex].chars.indices {
                let glyphY = columns[columnIndex].originY - CGFloat(rowOffset) * 18
                if glyphY < -30 || glyphY > bounds.height + 30 { continue }
                let isHead = rowOffset == 0
                let alpha = isHead
                    ? 1.0
                    : max(0.05, 1.0 - CGFloat(rowOffset) / CGFloat(columns[columnIndex].chars.count))
                let color = isHead
                    ? NSColor.white
                    : NSColor(srgbRed: 0.0, green: 1.0, blue: 0.25, alpha: alpha)
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                String(columns[columnIndex].chars[rowOffset])
                    .draw(at: NSPoint(x: columnX, y: glyphY), withAttributes: attrs)
            }
        }

        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed > 2.9 {
            let progress = min(1.0, (elapsed - 2.9) / 0.9)
            let alpha = progress
            let color = NSColor(srgbRed: 0.0, green: 1.0, blue: 0.35, alpha: alpha)
            let bigFont = NSFont(name: "Menlo-Bold", size: 56) ?? NSFont.monospacedSystemFont(ofSize: 56, weight: .bold)
            let glow = NSShadow()
            glow.shadowColor = color.withAlphaComponent(alpha * 0.9)
            glow.shadowBlurRadius = 18
            glow.shadowOffset = .zero
            let attrs: [NSAttributedString.Key: Any] = [
                .font: bigFont,
                .foregroundColor: color,
                .kern: 10,
                .shadow: glow
            ]
            let text = "WAKE UP, NEO."
            let size = text.size(withAttributes: attrs)
            let textPoint = NSPoint(x: (bounds.width - size.width) / 2,
                                    y: (bounds.height - size.height) / 2)
            text.draw(at: textPoint, withAttributes: attrs)
        }
    }
}

enum MatrixExitScreen {
@MainActor
    static func show(panel: PanelView, then completion: @escaping () -> Void) {
        guard let screen = NSScreen.main else {
            completion()
            return
        }
        MatrixVoice.shared.say(panel.theme.copy.spokenFarewell)
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = true
        window.backgroundColor = .black
        window.level = .screenSaver
        window.ignoresMouseEvents = true
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = MatrixRainView(frame: screen.frame)
        window.contentView = view
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)

        view.start {
            window.orderOut(nil)
            window.close()
            completion()
        }
    }
}
