import SwiftUI

public enum CircularProgressIndicatorSize {
    case small

    var dimension: CGFloat { 20 }
    var lineWidth: CGFloat { 2 }
}

public struct CircularProgressIndicator: View {
    public let size: CircularProgressIndicatorSize

    @State private var rotation: Double = 0

    public init(size: CircularProgressIndicatorSize = .small) {
        self.size = size
    }

    public var body: some View {
        Circle()
            .trim(from: 0, to: 0.66)
            .stroke(
                Color.encore("Primary/Dark"),
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
