import SwiftUI

struct RecipeChoiceView: View {
    let recipes: [Recipe]
    @State private var selectedRecipe: Recipe?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.neoBackground.ignoresSafeArea()
                TabView {
                    ForEach(recipes) { recipe in
                        Button {
                            selectedRecipe = recipe
                        } label: {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        styleChip(for: recipe.style)
                                        Spacer()
                                        Text("\(recipe.matchScore)% match")
                                            .font(.system(.subheadline, design: .rounded))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    Text(recipe.title)
                                        .font(.system(.title, design: .rounded).weight(.bold))
                                        .foregroundColor(.white)
                                    Text(recipe.description)
                                        .font(.system(.body, design: .rounded))
                                        .foregroundColor(.white.opacity(0.8))
                                    Divider().background(Color.white.opacity(0.2))
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(L("key_ingredients"))
                                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                            .foregroundColor(.white)
                                        Wrap(alignment: .leading, spacing: 6) {
                                            ForEach(recipe.ingredients.prefix(6)) { ingredient in
                                                IngredientChip(text: ingredient.name)
                                            }
                                        }
                                    }
                                    Divider().background(Color.white.opacity(0.2))
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(L("steps_title"))
                                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                            .foregroundColor(.white)
                                        ForEach(recipe.steps.prefix(3)) { step in
                                            HStack(alignment: .top, spacing: 8) {
                                                Circle()
                                                    .fill(Color.neoAccent)
                                                    .frame(width: 8, height: 8)
                                                Text(step.text)
                                                    .font(.system(.body, design: .rounded))
                                                    .foregroundColor(.white.opacity(0.9))
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .tabViewStyle(.page)
            }
            .navigationDestination(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe)
            }
        }
    }

    func styleChip(for style: RecipeStyle) -> some View {
        let text: String
        let color: Color
        let icon: String
        switch style {
        case .fast:
            text = "Fast"
            color = Color.neoAccent
            icon = "bolt.fill"
        case .healthy:
            text = "Healthy"
            color = .mint
            icon = "heart.fill"
        case .gourmet:
            text = "Gourmet"
            color = .purple
            icon = "sparkles"
        }
        return HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
                .font(.system(.footnote, design: .rounded).weight(.medium))
        }
        .foregroundColor(.black)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color)
        .clipShape(Capsule())
    }
}

private struct IngredientChip: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "leaf")
                .font(.system(size: 14, weight: .semibold))
            Text(text)
                .font(.system(.footnote, design: .rounded).weight(.medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.neoGlassBorder, lineWidth: 1)
        )
    }
}

