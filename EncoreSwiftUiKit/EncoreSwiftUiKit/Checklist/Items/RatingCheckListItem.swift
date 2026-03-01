import SwiftUI

/// Rating checklist item with star rating matching Figma design specifications.
/// Composes ChecklistHeader + RatingView.
/// Mirrors Android's `RatingCheckListItem` composable.
public struct RatingCheckListItem: View {
    let title: String
    let initialRating: Int
    let onRatingChange: (Int) -> Void
    let isRequired: Bool
    var maxStars: Int

    @State private var rating: Int

    public init(
        title: String,
        initialRating: Int,
        onRatingChange: @escaping (Int) -> Void,
        isRequired: Bool,
        maxStars: Int = 5
    ) {
        self.title = title
        self.initialRating = initialRating
        self.onRatingChange = onRatingChange
        self.isRequired = isRequired
        self.maxStars = maxStars
        self._rating = State(initialValue: initialRating)
    }

    private var isValid: Bool {
        ChecklistValidator.validateRating(rating, isRequired: isRequired)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChecklistHeader(
                title: title,
                isRequired: isRequired && !isValid
            )

            RatingView(
                rating: rating,
                onRatingChange: { newRating in
                    rating = newRating
                    onRatingChange(newRating)
                },
                maxStars: maxStars
            )
            .padding(.top, ChecklistItemConstants.innerTopPadding)
        }
        .padding(ChecklistItemConstants.itemPadding)
        .onChange(of: initialRating) { newValue in
            rating = newValue
        }
    }
}

