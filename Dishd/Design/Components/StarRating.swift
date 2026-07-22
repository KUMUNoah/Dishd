import SwiftUI

/// Read-only stars — terracotta, per the design system (hearts are tomato, stars are not).
struct StarRatingDisplay: View {
    let rating: Int
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Icon(star <= rating ? Lucide.starFill : Lucide.star, size: size)
                    .foregroundStyle(star <= rating ? DishdColor.terracotta : DishdColor.sand)
            }
        }
    }
}

/// Tappable star input for the review composer.
struct StarRatingInput: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(1...5, id: \.self) { star in
                Icon(star <= rating ? Lucide.starFill : Lucide.star, size: 32)
                    .foregroundStyle(star <= rating ? DishdColor.terracotta : DishdColor.sand)
                    .onTapGesture { rating = star }
            }
        }
    }
}
