import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @State private var results: [Profile] = []

    var body: some View {
        NavigationStack {
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
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(DishdColor.espresso)
                                }
                                .frame(width: 38, height: 38)

                                VStack(alignment: .leading, spacing: 1) {
                                    if let name = profile.fullName {
                                        Text(name)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(DishdColor.espresso)
                                    }
                                    Text("@\(profile.username)")
                                        .font(.system(size: 13))
                                        .foregroundStyle(DishdColor.taupe)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(DishdColor.taupe)
                            }
                            .padding(12)
                            .background(DishdColor.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(DishdColor.border, lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity)
            }
            .background(DishdColor.cream.ignoresSafeArea())
            .toolbarBackground(DishdColor.cream, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search usernames")
            .onChange(of: query) { Task { await search() } }
        }
        .tint(DishdColor.terracotta)
    }

    private func search() async {
        let current = query
        try? await Task.sleep(for: .milliseconds(300))
        guard current == query else { return }
        results = (try? await SocialService.searchUsers(current)) ?? []
    }
}
