import SwiftUI

/// Draws a set of pen strokes. When `fitToRect` is true the strokes are scaled
/// and centred to fill the rect (used for read-only previews and the PDF).
struct SignatureShape: Shape {
    var strokes: [[CGPoint]]
    var fitToRect: Bool = false

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let transform = fitToRect ? SignatureShape.fitTransform(for: strokes, in: rect) : .identity
        for stroke in strokes {
            guard let first = stroke.first else { continue }
            path.move(to: first.applying(transform))
            for point in stroke.dropFirst() {
                path.addLine(to: point.applying(transform))
            }
        }
        return path
    }

    static func fitTransform(for strokes: [[CGPoint]], in rect: CGRect) -> CGAffineTransform {
        let points = strokes.flatMap { $0 }
        guard let minX = points.map(\.x).min(),
              let maxX = points.map(\.x).max(),
              let minY = points.map(\.y).min(),
              let maxY = points.map(\.y).max() else { return .identity }
        let width = max(maxX - minX, 1)
        let height = max(maxY - minY, 1)
        let scale = min(rect.width / width, rect.height / height)
        let offsetX = rect.minX + (rect.width - width * scale) / 2
        let offsetY = rect.minY + (rect.height - height * scale) / 2
        return CGAffineTransform(translationX: -minX, y: -minY)
            .concatenating(CGAffineTransform(scaleX: scale, y: scale))
            .concatenating(CGAffineTransform(translationX: offsetX, y: offsetY))
    }
}

/// A finger-drawn signature box for section 10.
/// Shown in its own sheet so drawing doesn't fight with the form's scrolling.
struct SignaturePad: View {
    @Binding var strokes: [[CGPoint]]
    @State private var currentStroke: [CGPoint] = []

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.accentColor.opacity(0.6))

                if strokes.isEmpty && currentStroke.isEmpty {
                    Text("Sign here")
                        .foregroundStyle(.secondary)
                }

                SignatureShape(strokes: strokes + [currentStroke])
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            }
            .frame(height: 160)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        currentStroke.append(value.location)
                    }
                    .onEnded { _ in
                        if !currentStroke.isEmpty {
                            strokes.append(currentStroke)
                        }
                        currentStroke = []
                    }
            )
            .accessibilityLabel("Signature box")
            .accessibilityHint("Draw your signature with your finger")

            Button("Clear signature", role: .destructive) {
                strokes = []
            }
            .font(.footnote)
            .buttonStyle(.borderless)
            .disabled(strokes.isEmpty)
        }
    }
}

#Preview {
    @Previewable @State var strokes: [[CGPoint]] = []
    SignaturePad(strokes: $strokes).padding()
}
