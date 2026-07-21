import SwiftUI

/// One screen, two variants: your own profile (settings gear) or a
/// friend's (follow button, privacy lock).
struct ProfileView: View {
    let profile: Profile
    var isOwn: Bool = false

    @EnvironmentObject private var appState: AppState
    @State private var stats = ProfileStats(made: 0, followers: 0, following: 0)
    @State private var followState: FollowState = .notFollowing
    @State private var section = "history"
    @State private var reviews: [ProfileReview] = []
    @State private var saves: [SavedRecipe] = []
    @State private var showSettings = false
    @State private var isBlocked = false
    @State private var confirmingBlock = false
    @State private var reportingUser = false
    @State private var reportThanks = false

    private var contentVisible: Bool {
        !isBlocked && (isOwn || !profile.isPrivate || followState == .following)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header

                if isOwn {
                    GoalsCard()
                }

                if isBlocked {
                    blockedState
                } else if contentVisible {
                    SegmentedChips(options: [("history", "History"), ("recipes", "Recipes")],
                                   selection: $section)
                        .padding(.horizontal, 16)

                    if section == "history" {
                        historyList
                    } else {
                        recipeGrid
                    }
                } else {
                    lockState
                }
            }
            .padding(.vertical, 12)
        }
        .background(DishdColor.screen.ignoresSafeArea())
        .toolbarBackground(DishdColor.screen, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isOwn {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 19, weight: .medium))
                            .foregroundStyle(DishdColor.espresso)
                    }
                }
                .plainToolbarItem()
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { reportingUser = true } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 19, weight: .medium))
                            .foregroundStyle(DishdColor.espresso)
                    }
                }
                .plainToolbarItem()
            }
        }
        .sheet(isPresented: $reportingUser) {
            ModerationSheet(username: profile.username,
                            userId: profile.id,
                            onBlocked: {
                                followState = .notFollowing
                                isBlocked = true
                            },
                            onReported: { reportThanks = true })
        }
        .alert("Thanks — we'll take a look.", isPresented: $reportThanks) {
            Button("OK") {}
        }
        .sheet(isPresented: $showSettings) { SettingsSheet() }
        .task { await load() }
        .onChange(of: section) { Task { await loadContent() } }
    }

    private var header: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(DishdColor.honey)
                Text(String(profile.username.prefix(1)).uppercased())
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(DishdColor.espresso)
            }
            .frame(width: 72, height: 72)

            VStack(spacing: 2) {
                if let name = profile.fullName {
                    Text(name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(DishdColor.espresso)
                }
                HStack(spacing: 4) {
                    Text("@\(profile.username)")
                    if profile.isPrivate {
                        Image(systemName: "lock.fill").font(.system(size: 10))
                    }
                }
                .font(.system(size: 13))
                .foregroundStyle(DishdColor.taupe)
            }

            if let bio = profile.bio {
                Text(bio)
                    .font(.system(size: 13))
                    .foregroundStyle(DishdColor.espresso)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            HStack(spacing: 28) {
                stat(stats.made, "made")
                if contentVisible {
                    NavigationLink {
                        FollowListView(title: "Followers", userId: profile.id)
                    } label: {
                        stat(stats.followers, "followers")
                    }
                    .buttonStyle(.plain)
                    NavigationLink {
                        FollowListView(title: "Following", userId: profile.id)
                    } label: {
                        stat(stats.following, "following")
                    }
                    .buttonStyle(.plain)
                } else {
                    stat(stats.followers, "followers")
                    stat(stats.following, "following")
                }
            }
            .padding(.top, 4)

            if !isOwn {
                if isBlocked {
                    Button {
                        Task {
                            try? await SocialService.unblock(profile.id)
                            isBlocked = false
                            await load()
                        }
                    } label: {
                        Text("Unblock")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 9)
                            .background(DishdColor.tomato)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 6)
                } else {
                    followButton.padding(.top, 6)
                }
            }
        }
    }

    private func stat(_ value: Int, _ label: String) -> some View {
        VStack(spacing: 1) {
            Text("\(value)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DishdColor.espresso)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(DishdColor.taupe)
        }
    }

    private var followButton: some View {
        Button {
            Task { await toggleFollow() }
        } label: {
            Text(followState == .following ? "Following"
                 : followState == .pending ? "Requested" : "Follow")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(followState == .notFollowing ? .white : DishdColor.taupe)
                .padding(.horizontal, 32)
                .padding(.vertical, 9)
                .background(followState == .notFollowing ? DishdColor.terracotta : DishdColor.sand)
                .clipShape(Capsule())
        }
    }

    private var blockedState: some View {
        VStack(spacing: 8) {
            Image(systemName: "hand.raised")
                .font(.system(size: 26))
                .foregroundStyle(DishdColor.taupe)
            Text("You've blocked @\(profile.username)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DishdColor.espresso)
            Text("They can't see your cooking, and you can't see theirs.")
                .font(.system(size: 13))
                .foregroundStyle(DishdColor.taupe)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 24)
        .background(DishdColor.sand.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }

    private var lockState: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock")
                .font(.system(size: 26))
                .foregroundStyle(DishdColor.taupe)
            Text("Follow to see their cooking")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DishdColor.espresso)
            Text("Reviews and recipes are shared with approved followers.")
                .font(.system(size: 13))
                .foregroundStyle(DishdColor.taupe)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 24)
        .background(DishdColor.sand.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }

    private var historyList: some View {
        VStack(spacing: 10) {
            if reviews.isEmpty {
                Text(isOwn ? "Cooked something? Review it and it lands here."
                           : "No reviews yet.")
                    .font(.system(size: 14))
                    .foregroundStyle(DishdColor.taupe)
                    .padding(.top, 24)
            }
            ForEach(reviews) { review in
                HStack(spacing: 10) {
                    AsyncImage(url: URL(string: review.photoUrl)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: { DishdColor.sand }
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(review.recipe.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(DishdColor.espresso)
                        StarRatingDisplay(rating: review.rating, size: 11)
                    }
                    Spacer()
                    Text(review.createdAt.formatted(.relative(presentation: .named)))
                        .font(.system(size: 12))
                        .foregroundStyle(DishdColor.taupe)
                }
                .padding(12)
                .background(DishdColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(DishdColor.border, lineWidth: 0.5))
            }
        }
        .padding(.horizontal, 16)
    }

    private var recipeGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                  spacing: 12) {
            ForEach(saves) { save in
                NavigationLink {
                    RecipeDetailView(recipe: save.recipe)
                } label: {
                    RecipeTile(recipe: save.recipe)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    private func toggleFollow() async {
        switch followState {
        case .notFollowing:
            followState = profile.isPrivate ? .pending : .following
            try? await SocialService.follow(profile.id)
        case .following, .pending:
            followState = .notFollowing
            try? await SocialService.unfollow(profile.id)
        }
        await load()
    }

    private func load() async {
        if !isOwn {
            followState = await SocialService.followState(of: profile.id)
            isBlocked = await SocialService.isBlocked(profile.id)
        }
        stats = await SocialService.stats(for: profile.id)
        await loadContent()
    }

    private func loadContent() async {
        guard contentVisible else { return }
        do {
            if section == "history" {
                reviews = try await SocialService.reviews(of: profile.id)
            } else {
                saves = try await SocialService.saves(of: profile.id)
            }
        } catch {
            print("Profile content load failed: \(error)")
        }
    }
}

// MARK: - Settings building blocks (2d: grouped cream cards, no stock list)

/// Uppercase taupe section label above a cream card.
struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .kerning(0.66)
                .foregroundStyle(DishdColor.taupe)
                .padding(.horizontal, 4)
            VStack(spacing: 0) { content }
                .background(DishdColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(DishdColor.border, lineWidth: 1))
        }
    }
}

struct SettingsRow<Accessory: View>: View {
    let icon: String
    let title: String
    var subtitle: String?
    @ViewBuilder var accessory: Accessory

    init(icon: String, title: String, subtitle: String? = nil,
         @ViewBuilder accessory: () -> Accessory) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory()
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(DishdColor.terracotta)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DishdColor.espresso)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11.5))
                        .foregroundStyle(DishdColor.taupe)
                }
            }
            Spacer(minLength: 8)
            accessory
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}

struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(DishdColor.border)
            .frame(height: 1)
            .padding(.horizontal, 14)
    }
}

struct SettingsSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var isPrivate = false
    @State private var confirmingDelete = false
    @State private var deleteFailed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SettingsGroup("Account") {
                        SettingsRow(icon: "lock.fill", title: "Private account",
                                    subtitle: "Only approved followers see your cooking") {
                            Toggle("", isOn: $isPrivate)
                                .labelsHidden()
                                .tint(DishdColor.terracotta)
                                .onChange(of: isPrivate) {
                                    Task {
                                        try? await SocialService.setPrivate(isPrivate)
                                        await appState.loadProfile()
                                    }
                                }
                        }
                        SettingsDivider()
                        NavigationLink { GoalsEditorView() } label: {
                            SettingsRow(icon: "flag.fill", title: "Cooking goals") { chevron }
                        }
                    }

                    SettingsGroup("Privacy and safety") {
                        NavigationLink { BlockedUsersView() } label: {
                            SettingsRow(icon: "hand.raised.fill", title: "Blocked users") { chevron }
                        }
                    }

                    SettingsGroup("About") {
                        Link(destination: Legal.termsURL) {
                            SettingsRow(icon: "doc.text.fill", title: "Terms of Service") { linkGlyph }
                        }
                        SettingsDivider()
                        Link(destination: Legal.privacyURL) {
                            SettingsRow(icon: "shield.fill", title: "Privacy Policy") { linkGlyph }
                        }
                    }

                    VStack(spacing: 9) {
                        Button {
                            Task { await appState.signOut() }
                        } label: {
                            Text("Log out")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(DishdColor.terracotta)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(DishdColor.card)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(DishdColor.border, lineWidth: 1))
                        }
                        Button {
                            confirmingDelete = true
                        } label: {
                            Text("Delete account")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(DishdColor.tomato)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(DishdColor.dangerBorder, lineWidth: 1))
                        }
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(DishdColor.screen.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DishdColor.screen, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DishdColor.terracotta)
                }
                .plainToolbarItem()
            }
            .confirmationDialog(
                "Delete your account? Your recipes, reviews, and followers are permanently erased. This can't be undone.",
                isPresented: $confirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Delete my account", role: .destructive) {
                    Task {
                        do {
                            try await SocialService.deleteAccount()
                            await appState.signOut()
                        } catch {
                            deleteFailed = true
                        }
                    }
                }
            }
        }
        .alert("Couldn't delete your account. Check your connection and try again.",
               isPresented: $deleteFailed) {
            Button("OK", role: .cancel) {}
        }
        .onAppear { isPrivate = appState.profile?.isPrivate ?? false }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(DishdColor.chevron)
    }

    private var linkGlyph: some View {
        Image(systemName: "arrow.up.right.square")
            .font(.system(size: 14))
            .foregroundStyle(DishdColor.chevron)
    }
}

struct BlockedUsersView: View {
    @State private var blocked: [Profile] = []

    var body: some View {
        List {
            if blocked.isEmpty {
                Text("No blocked users.")
                    .foregroundStyle(DishdColor.taupe)
            }
            ForEach(blocked) { profile in
                HStack {
                    Text("@\(profile.username)")
                    Spacer()
                    Button("Unblock") {
                        Task {
                            try? await SocialService.unblock(profile.id)
                            blocked.removeAll { $0.id == profile.id }
                        }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DishdColor.terracotta)
                }
            }
        }
        .navigationTitle("Blocked users")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            blocked = (try? await SocialService.blockedUsers()) ?? []
        }
    }
}
