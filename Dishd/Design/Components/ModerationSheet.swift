import SwiftUI

/// Custom report/block bottom sheet — replaces the stock iOS action sheet.
/// Two stages: pick an action, then pick a report reason.
struct ModerationSheet: View {
    let username: String
    /// Nil when moderating a profile rather than a specific review.
    var reviewId: UUID?
    let userId: UUID
    var onBlocked: () -> Void = {}
    var onReported: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var stage: Stage = .actions
    @State private var working = false
    @State private var contentHeight: CGFloat = 320

    private enum Stage { case actions, reasons, blockConfirm }

    static let reasons = ["Spam", "Inappropriate content", "Harassment", "Not a real review"]

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(DishdColor.grabber)
                .frame(width: 48, height: 6)
                .padding(.top, 8)
                .padding(.bottom, 14)

            switch stage {
            case .actions:      actions
            case .reasons:      reasons
            case .blockConfirm: blockConfirm
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity)
        // Size the detent to the content so no stage leaves dead space.
        .background {
            GeometryReader { geo in
                DishdColor.screen
                    .onAppear { contentHeight = geo.size.height }
                    .onChange(of: geo.size.height) { contentHeight = geo.size.height }
            }
        }
        .presentationDetents([.height(contentHeight)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(34)
        .animation(.snappy(duration: 0.25), value: contentHeight)
    }

    // MARK: - Stage 1 · what would you like to do

    private var actions: some View {
        VStack(spacing: 0) {
            title("@\(username)", subtitle: "What would you like to do?")

            VStack(spacing: 10) {
                actionRow(icon: Lucide.flag,
                          title: "Report \(reviewId == nil ? "user" : "review")",
                          subtitle: "Tell us what's wrong — stays anonymous",
                          tint: DishdColor.terracotta,
                          fill: DishdColor.card,
                          stroke: DishdColor.border) { stage = .reasons }

                actionRow(icon: Lucide.ban,
                          title: "Block @\(username)",
                          subtitle: "You won't see each other's cooking",
                          tint: DishdColor.tomato,
                          fill: DishdColor.dangerTint,
                          stroke: DishdColor.dangerBorder) { stage = .blockConfirm }
            }

            cancelButton
        }
    }

    // MARK: - Stage 2 · report reasons

    private var reasons: some View {
        VStack(spacing: 0) {
            title("Why are you reporting this?",
                  subtitle: "We review every report within 24 hours.")

            VStack(spacing: 8) {
                ForEach(Self.reasons, id: \.self) { reason in
                    Button {
                        submitReport(reason)
                    } label: {
                        HStack {
                            Text(reason)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(DishdColor.espresso)
                            Spacer()
                            Icon(Lucide.chevronRight, size: 18)
                                .foregroundStyle(DishdColor.chevron)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .background(DishdColor.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(DishdColor.border, lineWidth: 1))
                    }
                    .disabled(working)
                }
            }

            cancelButton
        }
    }

    // MARK: - Stage 3 · confirm block

    private var blockConfirm: some View {
        VStack(spacing: 0) {
            title("Block @\(username)?",
                  subtitle: "They won't see your cooking, and you won't see theirs. You can undo this in Settings.")

            Button {
                Task {
                    working = true
                    try? await SocialService.block(userId)
                    onBlocked()
                    dismiss()
                }
            } label: {
                Text("Block @\(username)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(DishdColor.tomato)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(working)

            cancelButton
        }
    }

    // MARK: - Pieces

    private func title(_ text: String, subtitle: String) -> some View {
        VStack(spacing: 3) {
            Text(text)
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(DishdColor.espresso)
            Text(subtitle)
                .font(.system(size: 16))
                .foregroundStyle(DishdColor.taupe)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 16)
    }

    private func actionRow(icon: String, title: String, subtitle: String,
                           tint: Color, fill: Color, stroke: Color,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13).fill(DishdColor.screen)
                    RoundedRectangle(cornerRadius: 13).stroke(stroke, lineWidth: 1)
                    Icon(icon, size: 26)
                        .foregroundStyle(tint)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tint == DishdColor.tomato ? DishdColor.tomato : DishdColor.espresso)
                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundStyle(DishdColor.taupe)
                }
                Spacer(minLength: 0)
            }
            .padding(18)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: 21))
            .overlay(RoundedRectangle(cornerRadius: 21).stroke(stroke, lineWidth: 1))
        }
    }

    private var cancelButton: some View {
        Button {
            if stage == .actions { dismiss() } else { stage = .actions }
        } label: {
            Text(stage == .actions ? "Cancel" : "Back")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(DishdColor.taupe)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .padding(.top, 8)
    }

    private func submitReport(_ reason: String) {
        Task {
            working = true
            try? await SocialService.report(reviewId: reviewId, userId: reviewId == nil ? userId : nil,
                                            reason: reason)
            onReported()
            dismiss()
        }
    }
}
