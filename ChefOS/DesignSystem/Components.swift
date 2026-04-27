import SwiftUI

// MARK: - Core Surfaces

struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 20

    init(cornerRadius: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(
                Color.white.opacity(0.08)
                    .blur(radius: 0)
                    .background(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.neoGlassBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Buttons

enum NeoButtonStyle {
    case primary
    case secondary
}

struct NeoButton: View {
    let title: String
    var style: NeoButtonStyle = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(background)
                .foregroundColor(foreground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: shadowColor, radius: 12, x: 0, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(style == .secondary ? 0.15 : 0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var background: some View {
        switch style {
        case .primary:
            return LinearGradient(
                colors: [Color(hex: "#00c753"), Color(hex: "#00b048")],
                startPoint: .leading,
                endPoint: .trailing
            )
            .eraseToAnyView()
        case .secondary:
            return Color.white.opacity(0.08).eraseToAnyView()
        }
    }

    private var foreground: Color {
        style == .primary ? .black : .white
    }

    private var shadowColor: Color {
        style == .primary ? Color(hex: "#00c753").opacity(0.5) : .clear
    }
}

// MARK: - Text Fields

struct NeoTextField: View {
    let title: String
    @Binding var text: String
    var icon: String?
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 22)
            }
            if isSecure {
                SecureField(title, text: $text)
                    .textContentType(.password)
                    .foregroundColor(.white)
                    .placeholder(when: text.isEmpty) {
                        Text(title).foregroundColor(.white.opacity(0.4))
                    }
            } else {
                TextField(title, text: $text)
                    .foregroundColor(.white)
                    .placeholder(when: text.isEmpty) {
                        Text(title).foregroundColor(.white.opacity(0.4))
                    }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 56)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Tags

struct TagView: View {
    let text: String
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(text)
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color(hex: "#00c753") : Color.white.opacity(0.06))
            .foregroundColor(isSelected ? .black : .white)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// Adaptive wrap layout for tags/chips
public struct Wrap<Content: View>: View {
    let alignment: HorizontalAlignment
    let spacing: CGFloat
    let content: () -> Content

    public init(alignment: HorizontalAlignment = .leading, spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content
    }

    public var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: spacing)], alignment: alignment, spacing: spacing) {
            content()
        }
    }
}

// MARK: - Helpers

private extension View {
    func eraseToAnyView() -> AnyView { AnyView(self) }
}

private extension View {
    @ViewBuilder
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow { placeholder() }
            self
        }
    }
}

