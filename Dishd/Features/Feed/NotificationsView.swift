import SwiftUI

struct NotificationsView: View {
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = true

    private var requests: [AppNotification] {
        notifications.filter { $0.type == "follow_request" }
    }
    private var others: [AppNotification] {
        notifications.filter { $0.type != "follow_request" }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if isLoading {
                    ProgressView().padding(.top, 60)
                } else if notifications.isEmpty {
                    VStack(spacing: 6) {
                        Icon(Lucide.bell, size: 26)
                            .foregroundStyle(DishdColor.taupe)
                        Text("Nothing yet")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(DishdColor.espresso)
                    }
                    .padding(.top, 60)
                }

                // Follow requests pinned on top — the only ones demanding action.
                ForEach(requests) { notification in
                    requestRow(notification)
                }
                ForEach(others) { notification in
                    row(notification)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
        }
        .background(DishdColor.screen.ignoresSafeArea())
        .toolbarBackground(DishdColor.screen, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
            await SocialService.markAllRead()
        }
    }

    private func requestRow(_ notification: AppNotification) -> some View {
        HStack(spacing: 10) {
            avatar(notification)
            Text("**\(notification.actor.username)** requested to follow you")
                .font(.system(size: 13))
                .foregroundStyle(DishdColor.espresso)
            Spacer()
            Button {
                Task {
                    try? await SocialService.acceptRequest(from: notification.actorId)
                    await SocialService.deleteNotification(id: notification.id)
                    withAnimation { notifications.removeAll { $0.id == notification.id } }
                }
            } label: {
                Text("Accept")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(DishdColor.terracotta)
                    .clipShape(Capsule())
            }
            Button {
                Task {
                    try? await SocialService.declineRequest(from: notification.actorId)
                    await SocialService.deleteNotification(id: notification.id)
                    withAnimation { notifications.removeAll { $0.id == notification.id } }
                }
            } label: {
                Icon(Lucide.x, size: 13)
                    .foregroundStyle(DishdColor.taupe)
            }
        }
        .padding(12)
        .background(DishdColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(DishdColor.tomato, lineWidth: 1))
    }

    private func row(_ notification: AppNotification) -> some View {
        HStack(spacing: 10) {
            icon(for: notification.type)
            Text(text(for: notification))
                .font(.system(size: 13))
                .foregroundStyle(DishdColor.espresso)
            Spacer()
            Text(notification.createdAt.formatted(.relative(presentation: .named)))
                .font(.system(size: 12))
                .foregroundStyle(DishdColor.taupe)
        }
        .padding(12)
        .background(DishdColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(DishdColor.border, lineWidth: 0.5))
    }

    private func avatar(_ notification: AppNotification) -> some View {
        ZStack {
            Circle().fill(DishdColor.honey)
            Text(String(notification.actor.username.prefix(1)).uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DishdColor.espresso)
        }
        .frame(width: 32, height: 32)
    }

    @ViewBuilder
    private func icon(for type: String) -> some View {
        switch type {
        case "like":
            Icon(Lucide.heartFill).foregroundStyle(DishdColor.tomato)
        case "new_follower":
            Icon(Lucide.userPlus).foregroundStyle(DishdColor.honey)
        case "save_from_profile":
            Icon(Lucide.bookmarkFill).foregroundStyle(DishdColor.terracotta)
        default:
            Icon(Lucide.bell).foregroundStyle(DishdColor.taupe)
        }
    }

    private func text(for notification: AppNotification) -> AttributedString {
        let name = notification.actor.username
        switch notification.type {
        case "like": return (try? AttributedString(markdown: "**\(name)** liked your review")) ?? ""
        case "new_follower": return (try? AttributedString(markdown: "**\(name)** started following you")) ?? ""
        case "save_from_profile": return (try? AttributedString(markdown: "**\(name)** saved a recipe from your profile")) ?? ""
        default: return AttributedString(name)
        }
    }

    private func load() async {
        notifications = (try? await SocialService.notifications()) ?? []
        isLoading = false
    }
}
