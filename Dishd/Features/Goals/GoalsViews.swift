import SwiftUI

/// The two goal questions as chip rows. Shared by onboarding and Settings.
struct GoalsPicker: View {
    @Binding var cookPerWeek: Int?
    @Binding var newRecipesPerMonth: Int?

    static let weekOptions = [1, 2, 3, 5, 7]
    static let monthOptions = [2, 4, 6, 10]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                question("How often do you want to cook for yourself?")
                chipRow(Self.weekOptions, selection: $cookPerWeek) { "\($0)× a week" }
            }
            VStack(alignment: .leading, spacing: 10) {
                question("How many new recipes do you want to try a month?")
                chipRow(Self.monthOptions, selection: $newRecipesPerMonth) { "\($0)" }
                if let monthly = newRecipesPerMonth {
                    Text("That's \(monthly * 12) new dishes a year.")
                        .font(.system(size: 13))
                        .foregroundStyle(DishdColor.taupe)
                }
            }
        }
    }

    private func question(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(DishdColor.espresso)
    }

    private func chipRow(_ options: [Int], selection: Binding<Int?>,
                         label: @escaping (Int) -> String) -> some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.self) { option in
                let selected = selection.wrappedValue == option
                Text(label(option))
                    .font(.system(size: 13, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? .white : DishdColor.espresso)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity)
                    .background(selected ? DishdColor.terracotta : DishdColor.card)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(selected ? .clear : DishdColor.border, lineWidth: 0.5))
                    .onTapGesture { selection.wrappedValue = option }
            }
        }
    }
}

/// Progress toward goals, shown on the user's own profile.
/// If goals were skipped in onboarding, shows a set-up prompt instead.
struct GoalsCard: View {
    @State private var goals: Goals?
    @State private var progress: GoalsService.Progress?
    @State private var loaded = false

    var body: some View {
        Group {
            if let goals, let progress {
                VStack(spacing: 12) {
                    goalRow("This week", value: progress.cookedThisWeek,
                            target: goals.cookPerWeek, noun: "cooked")
                    goalRow("This month", value: progress.newRecipesThisMonth,
                            target: goals.newRecipesPerMonth, noun: "new recipes")
                }
                .padding(14)
                .background(DishdColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(DishdColor.border, lineWidth: 0.5))
                .padding(.horizontal, 16)
            } else if loaded {
                setUpPrompt
            }
        }
        .task { await load() }
        .onAppear { Task { await load() } }   // refresh after returning from the editor
    }

    private var setUpPrompt: some View {
        VStack(spacing: 6) {
            Text("Set your cooking goals")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DishdColor.espresso)
            Text("Pick how often you want to cook — we'll track your progress here.")
                .font(.system(size: 12))
                .foregroundStyle(DishdColor.taupe)
                .multilineTextAlignment(.center)
            NavigationLink {
                GoalsEditorView()
            } label: {
                Text("Set goals")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 7)
                    .background(DishdColor.terracotta)
                    .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(DishdColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(DishdColor.border, lineWidth: 0.5))
        .padding(.horizontal, 16)
    }

    private func load() async {
        goals = await GoalsService.get()
        if goals != nil { progress = await GoalsService.progress() }
        loaded = true
    }

    private func goalRow(_ title: String, value: Int, target: Int, noun: String) -> some View {
        let done = value >= target
        return VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DishdColor.espresso)
                Spacer()
                Text(done ? "\(value) of \(target) \(noun) 🎉" : "\(value) of \(target) \(noun)")
                    .font(.system(size: 12))
                    .foregroundStyle(DishdColor.taupe)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(DishdColor.sand)
                    Capsule()
                        .fill(done ? DishdColor.honey : DishdColor.terracotta)
                        .frame(width: geo.size.width * min(1, CGFloat(value) / CGFloat(max(target, 1))))
                }
            }
            .frame(height: 6)
        }
    }
}

/// Settings → Cooking goals. Saves on every change.
struct GoalsEditorView: View {
    @State private var cookPerWeek: Int?
    @State private var newRecipesPerMonth: Int?
    @State private var loaded = false

    var body: some View {
        ScrollView {
            GoalsPicker(cookPerWeek: $cookPerWeek,
                        newRecipesPerMonth: $newRecipesPerMonth)
                .padding(24)
        }
        .background(DishdColor.cream)
        .navigationTitle("Cooking goals")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let goals = await GoalsService.get() {
                cookPerWeek = goals.cookPerWeek
                newRecipesPerMonth = goals.newRecipesPerMonth
            }
            loaded = true
        }
        .onChange(of: cookPerWeek) { save() }
        .onChange(of: newRecipesPerMonth) { save() }
    }

    private func save() {
        guard loaded, let cook = cookPerWeek, let monthly = newRecipesPerMonth else { return }
        Task {
            try? await GoalsService.set(Goals(cookPerWeek: cook, newRecipesPerMonth: monthly))
        }
    }
}
