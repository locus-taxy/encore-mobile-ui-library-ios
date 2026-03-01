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
        HStack(spacing: 4) {
            ForEach(1 ... maxStars, id: \.self) { index in
                Button {
                    onRatingChange(index)
                } label: {
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .foregroundColor(index <= rating ? .yellow : .gray)
                        .font(.system(size: 28))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

