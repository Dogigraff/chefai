import SwiftUI

enum ImageMapper {
    static func placeholderName(for title: String) -> String? {
        let lower = title.lowercased()
        if lower.contains("chicken") { return "img_chicken_placeholder" }
        if lower.contains("pasta") { return "img_pasta_placeholder" }
        if lower.contains("salad") { return "img_salad_placeholder" }
        if lower.contains("pizza") { return "img_pizza_placeholder" }
        if lower.contains("soup") { return "img_soup_placeholder" }
        if lower.contains("beef") { return "img_beef_placeholder" }
        if lower.contains("fish") || lower.contains("salmon") { return "img_fish_placeholder" }
        return nil
    }

    static func placeholderView(for title: String) -> some View {
        let gradient = LinearGradient(
            colors: [Color(hex: "#0f2317"), Color(hex: "#1b2820"), Color.black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        return ZStack {
            gradient
            Text(title.prefix(1))
                .font(.system(size: 80, weight: .black, design: .rounded))
                .foregroundColor(.white.opacity(0.08))
        }
    }
}

