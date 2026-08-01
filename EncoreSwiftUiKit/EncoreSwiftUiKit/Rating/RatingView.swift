import SwiftUI

/// Reusable star rating view component matching Figma design specifications.
/// Can be used standalone or within checklist items.
/// Mirrors Android's `RatingView` composable.
public struct RatingView: View {
    let rating: Int
    let onRatingChange: (Int) -> Void
    var maxStars: Int

    public init(
        rating: Int,
        onRatingChange: @escaping (Int) -> Void,
        maxStars: Int = 5
    ) {
        self.rating = rating
        self.onRatingChange = onRatingChange
        self.maxStars = maxStars
    }

    public var body: some View {
        // Figma 2751-169320: five 40pt stars, no gap (each glyph is inset in its
        // 40pt box). Filled = Primary/Main, outline = Divider.
        HStack(spacing: 0) {
            ForEach(1 ... maxStars, id: \.self) { index in
                let filled = index <= rating
                Button {
                    onRatingChange(index)
                } label: {
                    EncoreIcon(iconName: filled ? "LStarFilled" : "LStarOutline", size: 40)
                        .foregroundColor(filled ? Color.encore("Primary/Main") : Color.encore("Divider"))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
