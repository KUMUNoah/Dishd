import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @State private var results: [Profile] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 2g: cream search field at the top. Not .searchable — iOS 26
                // docks that at the bottom, under the custom tab bar.
                HStack(spacing: 12) {
                    Icon(Lucide.search, size: 26)
                        .foregroundStyle(DishdColor.taupe)
                    TextField("Search usernames", text: $query)
                        .font(.system(size: 18))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(DishdColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(DishdColor.border, lineWidth: 1))
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

                searchResults
            }
            .background(DishdColor.screen.ignoresSafeArea())
            .toolbarBackground(DishdColor.screen, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: query) { Task { await search() } }
        }
        .tint(DishdColor.terracotta)
    }

    private var searchResults: some View {
            ScrollView {
                VStack(spacing: 10) {
                    if results.isEmpty && !query.isEmpty {
                        Text("No one found — check the spelling?")
                            .font(.system(size: 14))
                            .foregroundStyle(DishdColor.taupe)
                            .padding(.top, 30)
                    }
                    ForEach(results) { profile in
                        NavigationLink {
                            ProfileView(profile: profile)
                        } label: {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle().fill(DishdColor.honey)
                                    Text(String(profile.username.prefix(1)).uppercased())
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(DishdColor.espresso)
                                }
                                .frame(width: 50, height: 50)

                                VStack(alignment: .leading, spacing: 1) {
                                    if let name = profile.fullName {
                                        Text(name)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(DishdColor.espresso)
                                    }
                                    Text("@\(profile.username)")
                                        .font(.system(size: 16))
                                        .foregroundStyle(DishdColor.taupe)
                                }
                                Spacer()
                                Icon(Lucide.chevronRight, size: 17)
                                    .foregroundStyle(DishdColor.taupe)
                            }
                            .padding(14)
                            .background(DishdColor.card)
                            .clipShape(RoundedRectangle(cornerRadius: 21))
                            .overlay(RoundedRectangle(cornerRadius: 21).stroke(DishdColor.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity)
            }
    }

    private func search() async {
        let current = query
        try? await Task.sleep(for: .milliseconds(300))
        guard current == query else { return }
        results = (try? await SocialService.searchUsers(current)) ?? []
    }
}
