import SwiftUI
import PhotosUI

struct ReviewComposerView: View {
    let recipe: Recipe
    var onPosted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var rating = 0
    @State private var notes = ""
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo first — it's the proof.
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        if let photoData, let image = UIImage(data: photoData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 240)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            VStack(spacing: 6) {
                                Image(systemName: "camera")
                                    .font(.system(size: 28))
                                    .foregroundStyle(DishdColor.terracotta)
                                Text("Show how yours turned out")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(DishdColor.terracotta)
                                Text("Photo required — imperfect is fine")
                                    .font(.system(size: 13))
                                    .foregroundStyle(DishdColor.taupe)
                            }
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(DishdColor.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(DishdColor.border, style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                            )
                        }
                    }
                    .onChange(of: photoItem) {
                        Task {
                            if let data = try? await photoItem?.loadTransferable(type: Data.self) {
                                photoData = compress(data)
                            }
                        }
                    }

                    VStack(spacing: 6) {
                        StarRatingInput(rating: $rating)
                        Text(rating == 0 ? "Tap to rate" : "")
                            .font(.system(size: 13))
                            .foregroundStyle(DishdColor.taupe)
                    }

                    TextField("How did it go? Be honest — what would you change?",
                              text: $notes, axis: .vertical)
                        .lineLimit(4...8)
                        .padding(14)
                        .background(DishdColor.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(DishdColor.border, lineWidth: 0.5))

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundStyle(DishdColor.tomato)
                    }

                    PrimaryButton(title: isWorking ? "Posting…" : "Post",
                                  isEnabled: photoData != nil && rating > 0 && !isWorking) {
                        Task { await submit() }
                    }

                    Text("Posting moves this to your Made folder")
                        .font(.system(size: 12))
                        .foregroundStyle(DishdColor.taupe)
                }
                .padding(20)
            }
            .background(DishdColor.cream.ignoresSafeArea())
            .toolbarBackground(DishdColor.cream, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle(recipe.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").foregroundStyle(DishdColor.espresso)
                    }
                }
            }
        }
    }

    /// Target < 500KB per the spec — feed scrolling shouldn't pull multi-MB originals.
    private func compress(_ data: Data) -> Data {
        guard let image = UIImage(data: data) else { return data }
        var quality: CGFloat = 0.8
        var result = image.jpegData(compressionQuality: quality) ?? data
        while result.count > 500_000, quality > 0.3 {
            quality -= 0.1
            result = image.jpegData(compressionQuality: quality) ?? result
        }
        return result
    }

    private func submit() async {
        guard let photoData else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await ReviewService.post(recipeId: recipe.id, rating: rating,
                                         notes: notes, photoData: photoData)
            Analytics.log("review_posted", ["quick_post": recipe.sourceUrl == nil ? "true" : "false"])
            dismiss()
            onPosted()
        } catch {
            print("REVIEW FAILED: \(error)")
            errorMessage = "Couldn't post: \(error.localizedDescription)"
        }
    }
}
