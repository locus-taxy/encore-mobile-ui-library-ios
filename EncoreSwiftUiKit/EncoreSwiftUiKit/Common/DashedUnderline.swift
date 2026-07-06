import SwiftUI

/// A single horizontal line spanning the shape's width. Stroked with a dash
/// pattern it renders a dashed/dotted underline. Prefer the
/// `View.dashedUnderline(...)` modifier over using this shape directly.
public struct DashedUnderline: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

public extension View {
    /// Overlays a dashed (dotted) underline along the bottom edge of the view.
    /// - Parameters:
    ///   - color: The underline color.
    ///   - lineWidth: Stroke width; also the underline's height.
    ///   - dash: Dash pattern. The default `[1, 3]` with round caps reads as dots.
    ///   - offset: Vertical offset below the view's bottom edge.
    func dashedUnderline(
        color: Color,
        lineWidth: CGFloat = 1,
        dash: [CGFloat] = [1, 3],
        offset: CGFloat = 1
    ) -> some View {
        overlay(alignment: .bottom) {
            DashedUnderline()
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, dash: dash))
                .frame(height: lineWidth)
                .offset(y: offset)
        }
    }
}
