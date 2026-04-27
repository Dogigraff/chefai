import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    @State private var searchText: String = ""
    @State private var selectedCategory: String = "Popular"
    private let categories = [
        String(localized: "popular"),
        String(localized: "new"),
        String(localized: "quick_easy"),
        String(localized: "vegan"),
        String(localized: "low_carb")
    ]

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A").ignoresSafeArea()
            ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                searchBar
                categoriesView
                if viewModel.recipes.isEmpty {
                    emptyState
                } else {
                    Text(L("popular_recipes"))
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    NavigationStack {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(viewModel.recipes) { recipe in
                                NavigationLink {
                                    RecipeDetailView(recipe: recipe)
                                } label: {
                                    RecipeCard(recipe: recipe)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                Spacer(minLength: 80)
            }
                .padding(.top, 12)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(L("hello_chef"))
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                Text(L("what_cooking"))
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(.body, design: .rounded))
            }
            Spacer()
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person")
                        .foregroundColor(.white)
                )
        }
        .padding(.horizontal)
    }

    private var searchBar: some View {
        NeoTextField(title: String(localized: "search_recipes"), text: $searchText, icon: "magnifyingglass")
            .padding(.horizontal)
    }

    private var categoriesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { cat in
                    TagView(text: cat, isSelected: selectedCategory == cat) {
                        selectedCategory = cat
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text(L("no_recipes_yet"))
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundColor(.white)
            Text(L("scan_first_meal"))
                .font(.system(.body, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

