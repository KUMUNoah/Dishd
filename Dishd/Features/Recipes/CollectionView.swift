import SwiftUI

struct CollectionView: View {
    @State private var section = "want_to_make"
    @State private var saves: [SavedRecipe] = []
    @State private var isLoading = true
    @State private var showSaveSheet = false
    @State private var quickPostRecipe: Recipe?

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SegmentedChips(options: [("want_to_make", "Want to make"), ("made", "Made")],
                               selection: $section)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                ScrollView {
                    if isLoading {
                        ProgressView().padding(.top, 60)
                    } else if saves.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(saves) { save in
                                NavigationLink {
                                    RecipeDetailView(recipe: save.recipe,
                                                     saveStatus: save.status,
                                                     onChanged: { Task { await load() } })
                                } label: {
                                    RecipeTile(recipe: save.recipe)
                                }
                                .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            Task {
                                                try? await RecipeService.deleteSave(id: save.id)
                                                await load()
                                            }
                                        } label: {
                                            Label("Remove", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .refreshable { await load() }
            }
            .background(DishdColor.screen.ignoresSafeArea())
            .toolbarBackground(DishdColor.screen, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("Your recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSaveSheet = true
                    } label: {
                        // 2f: bare terracotta glyph, matching the 2c chrome.
                        Image(systemName: "plus")
                            .font(.system(size: 21, weight: .medium))
                            .foregroundStyle(DishdColor.terracotta)
                    }
                }
                .plainToolbarItem()
            }
            .sheet(isPresented: $showSaveSheet) {
                SaveSheet(onSaved: { Task { await load() } },
                          onQuickPost: { recipe in quickPostRecipe = recipe })
            }
            .sheet(item: $quickPostRecipe) { recipe in
                ReviewComposerView(recipe: recipe) {
                    section = "made"
                    Task { await load() }
                }
            }
            .task { await load() }
            .onChange(of: section) { Task { await load() } }
        }
        .tint(DishdColor.terracotta)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: section == "want_to_make" ? "bookmark" : "frying.pan")
                .font(.system(size: 30))
                .foregroundStyle(DishdColor.taupe)
            Text(section == "want_to_make" ? "Nothing saved yet" : "Nothing made yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DishdColor.espresso)
            Text(section == "want_to_make"
                 ? "Found a recipe worth trying? Tap + to save it."
                 : "Cook something from your list and review it — it lands here.")
                .font(.system(size: 14))
                .foregroundStyle(DishdColor.taupe)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 60)
    }

    private func load() async {
        do {
            saves = try await RecipeService.mySaves(status: section)
        } catch {
            print("Load failed: \(error)")
        }
        isLoading = false
    }
}
