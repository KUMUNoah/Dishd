import SwiftUI

struct FollowListView: View {
    let title: String                 // "Followers" or "Following"
    let userId: UUID

    @State private var profiles: [Profile] = []
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if isLoading {
                    ProgressView().padding(.top, 50)
                } else if profiles.isEmpty {
                    Text(title == "Followers" ? "No followers yet." : "Not following anyone yet.")
                        .font(.system(size: 14))
                        .foregroundStyle(DishdColor.taupe)
                        .padding(.top, 50)
                }
                ForEach(profiles) { profile in
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
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            profiles = (try? await (title == "Followers"
                ? SocialService.followers(of: userId)
                : SocialService.following(of: userId))) ?? []
            isLoading = false
        }
    }
}
