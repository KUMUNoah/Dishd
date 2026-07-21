import SwiftUI

struct RecipeTile: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            thumbnail
                .frame(height: 110)
                .frame(maxWidth: .infinity)
                .clipped()

            VStack(alignment: .leading, spacing: 3) {
                Text(recipe.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DishdColor.espresso)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if let platform = recipe.platform {
                    Text(platformLabel(platform))
                        .font(.system(size: 12))
                        .foregroundStyle(DishdColor.taupe)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DishdColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(DishdColor.border, lineWidth: 1))
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let urlString = recipe.thumbnailUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                placeholderView
            }
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        ZStack {
            DishdColor.sand
            Image(systemName: "photo")
                .foregroundStyle(DishdColor.taupe)
        }
    }

    private func platformLabel(_ platform: String) -> String {
        switch platform {
        case "tiktok": "TikTok"
        case "instagram": "Instagram"
        case "youtube": "YouTube"
        default: "Web"
        }
    }
}
