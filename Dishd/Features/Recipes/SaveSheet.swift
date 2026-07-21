import SwiftUI

enum SaveSheetMode: String, CaseIterable {
    case saveForLater = "Save for later"
    case iMadeThis = "I made this"
}

struct SaveSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSaved: () -> Void
    /// Quick post: hands the recipe to the review composer (Milestone 3).
    var onQuickPost: ((Recipe) -> Void)? = nil

    @State private var mode: SaveSheetMode = .saveForLater
    @State private var title = ""
    @State private var link = ""
    @State private var isWorking = false
    @State private var errorMessage: String?

    private var formValid: Bool {
        switch mode {
        case .saveForLater: !title.isEmpty && !link.isEmpty
        case .iMadeThis: !title.isEmpty
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(DishdColor.border)
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            Picker("Mode", selection: $mode) {
                ForEach(SaveSheetMode.allCases, id: \.self) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented)

            if mode == .iMadeThis {
                Text("Cooked something already? Name it and go straight to your review.")
                    .font(.system(size: 13))
                    .foregroundStyle(DishdColor.taupe)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(mode == .saveForLater ? "Recipe name" : "What did you make?")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DishdColor.taupe)
                TextField("Chicken adobo", text: $title)
                    .padding(14)
                    .background(DishdColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(DishdColor.border, lineWidth: 0.5))
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text("Link")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DishdColor.taupe)
                    if mode == .iMadeThis {
                        Text("· optional")
                            .font(.system(size: 13))
                            .foregroundStyle(DishdColor.taupe.opacity(0.7))
                    }
                }
                TextField(mode == .iMadeThis ? "Paste if it came from a video" : "Paste a TikTok, Instagram, or YouTube link",
                          text: $link)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(DishdColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(DishdColor.border, lineWidth: 0.5))
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(DishdColor.tomato)
            }

            PrimaryButton(
                title: isWorking ? "Saving…"
                    : mode == .saveForLater ? "Save to Want to make" : "Continue to review",
                isEnabled: formValid && !isWorking
            ) {
                Task { await submit() }
            }

            if mode == .iMadeThis {
                Text("Lands in your Made folder once posted")
                    .font(.system(size: 12))
                    .foregroundStyle(DishdColor.taupe)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .background(DishdColor.screen)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }

    private func submit() async {
        isWorking = true
        defer { isWorking = false }
        do {
            switch mode {
            case .saveForLater:
                try await RecipeService.save(title: title, sourceUrl: link)
                onSaved()
                dismiss()
            case .iMadeThis:
                let recipe = try await RecipeService.save(
                    title: title,
                    sourceUrl: link.isEmpty ? nil : link,
                    status: "made"
                )
                dismiss()
                onQuickPost?(recipe)
            }
        } catch {
            print("SAVE FAILED: \(error)")
            errorMessage = "Couldn't save: \(error.localizedDescription)"
        }
    }
}
