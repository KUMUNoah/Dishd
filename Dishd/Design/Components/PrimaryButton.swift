import SwiftUI

/// Terracotta pill — the one accent-filled button per screen.
struct PrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isEnabled ? DishdColor.terracotta : DishdColor.terracotta.opacity(0.35))
                .clipShape(Capsule())
        }
        .disabled(!isEnabled)
    }
}

/// Bordered pill for secondary actions (Invite, Watch original).
struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DishdColor.terracotta)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(DishdColor.card)
                .overlay(Capsule().stroke(DishdColor.terracotta, lineWidth: 1))
                .clipShape(Capsule())
        }
    }
}
