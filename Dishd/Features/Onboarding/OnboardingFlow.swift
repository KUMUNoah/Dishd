import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject private var appState: AppState
    @State private var step = 1

    // Taste answer carried into the starter step — memory only,
    // used once to filter suggestions, never persisted.
    @State private var cuisines: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("STEP \(step) OF 4")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DishdColor.terracotta)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            switch step {
            case 1: FindFriendsStep(onContinue: { step = 2 })
            case 2: TasteStep(cuisines: $cuisines, onContinue: { step = 3 })
            case 3: GoalsStep(onContinue: { step = 4 })
            default: StarterStep(cuisines: cuisines, onDone: finish)
            }
        }
        .background(DishdColor.screen.ignoresSafeArea())
    }

    private func finish() {
        Analytics.log("onboarding_complete")
        appState.completeOnboarding()
    }
}

// MARK: - Step 1 · Find friends

private struct FindFriendsStep: View {
    var onContinue: () -> Void
    @State private var query = ""
    @State private var results: [Profile] = []
    @State private var followed: Set<UUID> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("See what your friends are cooking")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(DishdColor.espresso)
                Text("dishd is better with friends. Search usernames, or invite people to join you.")
                    .font(.system(size: 14))
                    .foregroundStyle(DishdColor.taupe)
            }

            TextField("Search usernames", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(DishdColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(DishdColor.border, lineWidth: 0.5))
                .onChange(of: query) { Task { await search() } }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(results) { profile in
                        HStack(spacing: 10) {
                            ZStack {
                                Circle().fill(DishdColor.honey)
                                Text(String(profile.username.prefix(1)).uppercased())
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(DishdColor.espresso)
                            }
                            .frame(width: 34, height: 34)

                            Text("@\(profile.username)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(DishdColor.espresso)
                            Spacer()

                            Button {
                                Task {
                                    try? await SocialService.follow(profile.id)
                                    followed.insert(profile.id)
                                }
                            } label: {
                                Text(followed.contains(profile.id) ? "Following" : "Follow")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(followed.contains(profile.id) ? DishdColor.taupe : .white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(followed.contains(profile.id) ? DishdColor.sand : DishdColor.terracotta)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(10)
                        .background(DishdColor.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(DishdColor.border, lineWidth: 0.5))
                    }
                }
            }

            ShareLink(item: URL(string: "https://apps.apple.com")!,
                      subject: Text("Join me on dishd"),
                      message: Text("I'm on dishd — it shows what friends are actually cooking. Join and follow me!")) {
                Label("Invite friends", systemImage: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DishdColor.terracotta)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(DishdColor.card)
                    .overlay(Capsule().stroke(DishdColor.terracotta, lineWidth: 1))
                    .clipShape(Capsule())
            }

            PrimaryButton(title: "Continue", action: onContinue)

            Button("Skip for now", action: onContinue)
                .font(.system(size: 13))
                .foregroundStyle(DishdColor.taupe)
                .frame(maxWidth: .infinity)
        }
        .padding(24)
    }

    private func search() async {
        let current = query
        try? await Task.sleep(for: .milliseconds(300))
        guard current == query else { return }
        results = (try? await SocialService.searchUsers(current)) ?? []
    }
}

// MARK: - Step 2 · Taste questions

private struct TasteStep: View {
    @Binding var cuisines: Set<String>
    var onContinue: () -> Void

    private let cuisineOptions = ["Italian", "Mexican", "Japanese", "Korean",
                                  "Thai", "Filipino", "Indian", "American",
                                  "Chinese", "Mediterranean"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("What sounds good?")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(DishdColor.espresso)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                    ForEach(cuisineOptions, id: \.self) { cuisine in
                        let selected = cuisines.contains(cuisine.lowercased())
                        Text(cuisine)
                            .font(.system(size: 13, weight: selected ? .semibold : .regular))
                            .foregroundStyle(selected ? .white : DishdColor.espresso)
                            .padding(.vertical, 9)
                            .frame(maxWidth: .infinity)
                            .background(selected ? DishdColor.terracotta : DishdColor.card)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(selected ? .clear : DishdColor.border, lineWidth: 0.5))
                            .onTapGesture {
                                if selected { cuisines.remove(cuisine.lowercased()) }
                                else { cuisines.insert(cuisine.lowercased()) }
                            }
                    }
                }

                PrimaryButton(title: "Continue", action: onContinue)
                    .padding(.top, 8)
            }
            .padding(24)
        }
    }
}

// MARK: - Step 3 · Cooking goals

private struct GoalsStep: View {
    var onContinue: () -> Void
    @State private var cookPerWeek = GoalsPicker.defaultCookPerWeek
    @State private var newRecipesPerYear = GoalsPicker.defaultNewRecipesPerYear

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Set your cooking goals")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(DishdColor.espresso)
                    Text("We'll track your progress on your profile. Change these anytime in Settings.")
                        .font(.system(size: 14))
                        .foregroundStyle(DishdColor.taupe)
                }

                GoalsPicker(cookPerWeek: $cookPerWeek,
                            newRecipesPerYear: $newRecipesPerYear)

                PrimaryButton(title: "Continue") {
                    let goals = Goals(cookPerWeek: cookPerWeek,
                                      newRecipesPerYear: newRecipesPerYear)
                    Task { try? await GoalsService.set(goals) }
                    Analytics.log("goals_set", ["cook_per_week": "\(cookPerWeek)",
                                                "new_recipes_per_year": "\(newRecipesPerYear)"])
                    onContinue()
                }
                .padding(.top, 8)

                Button("Skip for now", action: onContinue)
                    .font(.system(size: 13))
                    .foregroundStyle(DishdColor.taupe)
                    .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
    }
}

// MARK: - Step 4 · Starter recipes

private struct StarterStep: View {
    let cuisines: Set<String>
    var onDone: () -> Void

    @State private var starters: [RecipeService.StarterRecipe] = []
    @State private var savedIds: Set<UUID> = []
    @State private var showSaveSheet = false
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Here's what we think you'd like")
                        .font(DishdFont.wordmark(21))
                        .foregroundStyle(DishdColor.espresso)
                    Text("Save anything that looks good — it goes to your Want to make list.")
                        .font(.system(size: 14))
                        .foregroundStyle(DishdColor.taupe)
                }

                if isLoading {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                                        GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(starters) { starter in
                            VStack(spacing: 0) {
                                RecipeTile(recipe: starter.recipe)
                                    .overlay(alignment: .topTrailing) {
                                        Text(starter.timeLabel)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(DishdColor.espresso)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(.white.opacity(0.92))
                                            .clipShape(Capsule())
                                            .padding(6)
                                    }
                                Button {
                                    Task {
                                        try? await RecipeService.save(title: starter.recipe.title,
                                                                      sourceUrl: starter.recipe.sourceUrl)
                                        savedIds.insert(starter.id)
                                        Analytics.log("recipe_saved", ["source": "starter"])
                                    }
                                } label: {
                                    Text(savedIds.contains(starter.id) ? "Saved ✓" : "Save")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(savedIds.contains(starter.id) ? DishdColor.taupe : .white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 6)
                                        .background(savedIds.contains(starter.id) ? DishdColor.sand : DishdColor.terracotta)
                                        .clipShape(Capsule())
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                }

                Button {
                    showSaveSheet = true
                } label: {
                    Label("Have a recipe in mind? Paste a link", systemImage: "link")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DishdColor.terracotta)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(DishdColor.card)
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(DishdColor.border, style: StrokeStyle(lineWidth: 1, dash: [5])))
                }

                PrimaryButton(title: "Start cooking", action: onDone)
            }
            .padding(24)
        }
        .fullScreenCover(isPresented: $showSaveSheet) {
            SaveSheet(onSaved: {})
        }
        .task { await load() }
    }

    private func load() async {
        starters = (try? await RecipeService.starters(cuisines: Array(cuisines))) ?? []
        isLoading = false
    }
}
