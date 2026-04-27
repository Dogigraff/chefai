import SwiftUI

struct RecipeDetailView: View, Identifiable {
    let id = UUID()
    let recipe: Recipe
    @State private var substitutions: Set<UUID> = []
    @State private var showCooking: Bool = false
    @State private var headerHeight: CGFloat = 360

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                ParallaxHeader(imageURL: nil, title: recipe.title, style: recipe.style, time: estimateTime(), calories: recipe.nutrition.calories)
                    .frame(height: headerHeight)
                    .overlay(
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: HeaderHeightKey.self, value: geo.size.height)
                        }
                    )
                VStack(spacing: 16) {
                    GlassCard(cornerRadius: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L("ingredients"))
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                                .foregroundColor(.white)
                            ForEach(recipe.ingredients) { ingredient in
                                IngredientRow(
                                    ingredient: ingredient,
                                    substitute: recipe.smartSubstitutions[ingredient.name],
                                    reason: recipe.substitutionReasons[ingredient.name],
                                    isToggled: substitutions.contains(ingredient.id),
                                    toggle: {
                                        if substitutions.contains(ingredient.id) {
                                            substitutions.remove(ingredient.id)
                                        } else {
                                            substitutions.insert(ingredient.id)
                                        }
                                    }
                                )
                            }
                        }
                    }

                    if !recipe.missingIngredients.isEmpty {
                        GlassCard(cornerRadius: 24) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(L("missing_items"))
                                    .font(.system(.title3, design: .rounded).weight(.semibold))
                                    .foregroundColor(.white)
                                ForEach(recipe.missingIngredients) { ingredient in
                                    HStack {
                                        Text(ingredient.name)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text(ingredient.quantity)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .font(.system(.body, design: .rounded))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 120)
            }

            NeoButton(title: String(localized: "start_cooking")) {
                showCooking = true
            }
            .padding()
            .background(
                LinearGradient(colors: [Color.clear, Color.black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .background(Color(hex: "#0A0A0A").ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCooking) {
            CookingModeView(recipe: recipe)
        }
        .onPreferenceChange(HeaderHeightKey.self) { height in
            headerHeight = height
        }
    }
}

private extension RecipeDetailView {
    func estimateTime() -> Int {
        let base = recipe.steps.count * 3
        let timers = recipe.steps.compactMap { $0.timerSeconds }.reduce(0, +) / 60
        return max(10, base + timers)
    }
}

private struct ParallaxHeader: View {
    let imageURL: String?
    let title: String
    let style: RecipeStyle
    let time: Int
    let calories: Int

    var body: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            let height = geo.size.height
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: imageURL ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        if let placeholderName = ImageMapper.placeholderName(for: title) {
                            Image(placeholderName)
                                .resizable()
                                .scaledToFill()
                        } else {
                            ImageMapper.placeholderView(for: title)
                        }
                    }
                }
                .frame(width: geo.size.width, height: height + (minY > 0 ? minY : 0))
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [Color.black.opacity(0.8), Color.black.opacity(0.3), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .offset(y: (minY > 0 ? -minY : 0))

                VStack(alignment: .leading, spacing: 10) {
                    styleChip(for: style)
                    Text(title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    HStack(spacing: 10) {
                        TagView(text: "\(time) min", isSelected: true) {}
                        TagView(text: "\(calories) kcal", isSelected: false) {}
                    }
                }
                .padding()
                .padding(.bottom, 18)
            }
        }
    }

    private func styleChip(for style: RecipeStyle) -> some View {
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

private struct IngredientRow: View {
    let ingredient: Ingredient
    let substitute: String?
    let reason: String?
    let isToggled: Bool
    let toggle: () -> Void

    @State private var showReason: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(
                get: { isToggled },
                set: { _ in toggle() }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(displayName)
                            .foregroundColor(.white)
                            .font(.system(.body, design: .rounded).weight(.medium))
                        
                        if let substitute, !isToggled {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 12))
                                .foregroundColor(.neoAccent)
                        }
                    }
                    Text(ingredient.quantity)
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(.footnote, design: .rounded))
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .neoAccent))

            if isToggled, let reason {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.neoAccent.opacity(0.8))
                        .font(.system(size: 14))
                    Text(reason)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 8)
        .animation(.spring(), value: isToggled)
    }

    private var displayName: String {
        if isToggled, let substitute {
            return "\(ingredient.name) → \(substitute)"
        }
        return ingredient.name
    }
}

private struct HeaderHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 320
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

