import SwiftUI

struct RecipeCard: View {
    let recipe: Recipe
    var imageURL: String?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: imageURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    if let placeholderName = ImageMapper.placeholderName(for: recipe.title) {
                        Image(placeholderName)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ImageMapper.placeholderView(for: recipe.title)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(4/5, contentMode: .fit)
            .clipped()

            LinearGradient(
                colors: [Color.black.opacity(0.85), Color.black.opacity(0.35), .clear],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(maxWidth: .infinity)
            .aspectRatio(4/5, contentMode: .fit)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    tag(icon: "clock", text: timeTag)
                    tag(icon: "flame.fill", text: "\(recipe.nutrition.calories) kcal")
                    ratingTag
                }
                Text(recipe.title)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .shadow(radius: 6)
                Text(recipe.description)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
            .padding(14)
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 8)
    }

    private var timeTag: String {
        let mins = max(10, recipe.steps.count * 3)
        return "\(mins) min"
    }

    private func tag(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(.system(.caption, design: .rounded).weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.12))
        .foregroundColor(.white)
        .clipShape(Capsule())
    }

    private var ratingTag: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(.system(size: 12, weight: .bold))
            Text("\(recipe.matchScore)")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.35))
        .clipShape(Capsule())
    }
}

