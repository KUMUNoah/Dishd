import SwiftUI

enum SaveSheetMode: String, CaseIterable {
    case saveForLater = "Save for later"
    case iMadeThis = "I made this"
}

/// Full-screen composer (design turn 3) — was a medium sheet. Two modes:
/// save a link for later, or name something you already cooked and go
/// straight to the review.
struct SaveSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSaved: () -> Void
    /// Quick post: hands the recipe to the review composer.
    var onQuickPost: ((Recipe) -> Void)? = nil

    @State private var mode = SaveSheetMode.saveForLater.rawValue
    @State private var title = ""
    @State private var link = ""
    @State private var isWorking = false
    @State private var errorMessage: String?
    /// Populated once a pasted link is recognised.
    @State private var detected: RecipeService.Metadata?
    @State private var detectedPlatform: String?

    private var isSaveForLater: Bool { mode == SaveSheetMode.saveForLater.rawValue }

    private var formValid: Bool {
        isSaveForLater ? (!title.isEmpty && !link.isEmpty) : !title.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PageHeader(title: "Add a recipe", icon: Lucide.x) { dismiss() }
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        SegmentedChips(options: SaveSheetMode.allCases.map { ($0.rawValue, $0.rawValue) },
                                       selection: $mode)
                            .padding(.bottom, 26)

                        fieldLabel(isSaveForLater ? "Recipe name" : "What did you make?")
                        TextField(isSaveForLater ? "Gochujang glazed noodles" : "Chicken adobo",
                                  text: $title)
                            .font(.system(size: 18))
                            .padding(18)
                            .background(DishdColor.card)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18)
                                .stroke(DishdColor.border, lineWidth: 1))
                            .padding(.bottom, 26)

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            fieldLabel(isSaveForLater ? "Recipe link" : "Link")
                            if !isSaveForLater {
                                Text("· optional")
                                    .font(.system(size: 14))
                                    .foregroundStyle(DishdColor.chevron)
                            }
                        }
                        linkField

                        if isSaveForLater, let detected {
                            linkPreview(detected)
                                .padding(.top, 16)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 15))
                        .foregroundStyle(DishdColor.tomato)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 6)
                }

                submitBar
            }
            .background(DishdColor.screen.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .task { await detectLink() }
            .onChange(of: link) { Task { await detectLink() } }
            .onChange(of: mode) { errorMessage = nil }
        }
    }

    // MARK: - Pieces

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 14, weight: .semibold))
            .kerning(0.84)
            .foregroundStyle(DishdColor.taupe)
            .padding(.bottom, 10)
            .padding(.horizontal, 2)
    }

    private var linkField: some View {
        HStack(spacing: 13) {
            Icon(Lucide.link, size: 26)
                .foregroundStyle(isSaveForLater ? DishdColor.taupe : DishdColor.chevron)

            TextField(isSaveForLater ? "Paste a video link"
                                     : "Paste if it came from a video",
                      text: $link)
                .font(.system(size: 17))
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if link.isEmpty, UIPasteboard.general.hasURLs {
                Button {
                    link = UIPasteboard.general.url?.absoluteString
                        ?? UIPasteboard.general.string ?? ""
                } label: {
                    Text("Paste")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DishdColor.terracotta)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(DishdColor.screen)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(DishdColor.border, lineWidth: 1))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(DishdColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(DishdColor.border, lineWidth: 1))
    }

    /// Confirms the link was understood: thumbnail (when the platform allows
    /// scraping) plus a source chip.
    private func linkPreview(_ metadata: RecipeService.Metadata) -> some View {
        HStack(spacing: 14) {
            Group {
                if let thumb = metadata.thumbnailUrl, let url = URL(string: thumb) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        DishdColor.sand
                    }
                } else {
                    ZStack {
                        DishdColor.sand
                        Icon(Lucide.image, size: 24).foregroundStyle(DishdColor.taupe)
                    }
                }
            }
            .frame(width: 68, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Icon(Lucide.playCircle, size: 17)
                        .foregroundStyle(DishdColor.terracotta)
                    Text(platformLabel(detectedPlatform ?? "web"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DishdColor.espresso)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 4)
                .background(DishdColor.screen)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(DishdColor.border, lineWidth: 1))

                Text(metadata.thumbnailUrl == nil
                     ? "Link detected"
                     : "Link detected — thumbnail pulled in")
                    .font(.system(size: 15))
                    .foregroundStyle(DishdColor.taupe)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .background(DishdColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 21))
        .overlay(RoundedRectangle(cornerRadius: 21).stroke(DishdColor.border, lineWidth: 1))
    }

    private var submitBar: some View {
        VStack(spacing: 0) {
            Button {
                Task { await submit() }
            } label: {
                Text(isWorking ? "Saving…"
                     : isSaveForLater ? "Save to Want to make" : "Continue to review")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 19)
                    .background(formValid && !isWorking
                                ? DishdColor.terracotta
                                : DishdColor.terracotta.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .disabled(!formValid || isWorking)
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 8)
        .background(alignment: .top) {
            ZStack(alignment: .top) {
                DishdColor.screen
                Rectangle().fill(DishdColor.hairline).frame(height: 1)
            }
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

    // MARK: - Behaviour

    /// Debounced so it doesn't fire on every keystroke while pasting.
    private func detectLink() async {
        let current = link
        guard !current.isEmpty, URL(string: current)?.host != nil else {
            detected = nil; detectedPlatform = nil
            return
        }
        try? await Task.sleep(for: .milliseconds(400))
        guard current == link else { return }

        detectedPlatform = RecipeService.detectPlatform(current)
        let metadata = await RecipeService.fetchMetadata(for: current)
        guard current == link else { return }
        // Show the card even when scraping is blocked — the platform alone
        // confirms we understood the link.
        detected = metadata ?? RecipeService.Metadata(title: nil, thumbnailUrl: nil)
        if title.isEmpty, let scraped = metadata?.title, !scraped.isEmpty {
            title = scraped
        }
    }

    private func submit() async {
        isWorking = true
        defer { isWorking = false }
        do {
            if isSaveForLater {
                try await RecipeService.save(title: title, sourceUrl: link)
                onSaved()
                dismiss()
            } else {
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
