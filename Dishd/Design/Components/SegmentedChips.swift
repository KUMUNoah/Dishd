import SwiftUI

/// Cream track with a terracotta selected pill — replaces the stock
/// `.segmented` Picker so the chrome matches the cream-card system.
struct SegmentedChips: View {
    /// (tag, label) pairs, in order.
    let options: [(String, String)]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.0) { tag, label in
                let selected = selection == tag
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(selected ? .white : DishdColor.taupe)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background {
                        if selected {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(DishdColor.terracotta)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.snappy(duration: 0.18)) { selection = tag }
                    }
            }
        }
        .padding(3)
        .background(DishdColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(DishdColor.border, lineWidth: 1))
    }
}
