import SwiftUI

public enum CircularProgressIndicatorSize {
    case small

    var dimension: CGFloat { 15 }
    var lineWidth: CGFloat { 2 }
}

public struct CircularProgressIndicator: View {
    public let size: CircularProgressIndicatorSize
    public let color: Color

    @State private var rotation: Double = 0

    public init(size: CircularProgressIndicatorSize = .small, color: Color = Color.encore("Primary/Dark")) {
        self.size = size
        self.color = color
    }

    public var body: some View {
        Circle()
            .trim(from: 0, to: 0.66)
            .stroke(
                color,
                style: StrokeStyle(lineWidth: size.lineWidth, lineCap: .round)
            )
            .frame(width: size.dimension, height: size.dimension)
            .rotationEffect(.degrees(rotation - 90))
            .onAppear {
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

#Preview {
    CircularProgressIndicator(size: .small)
        .padding()
}
