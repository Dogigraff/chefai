import SwiftUI

struct MedicalProfileView: View {
    let onFinished: () -> Void

    @State private var selected: Set<String> = []
    private let options = ["Diabetes", "Halal", "Keto", "Hypertension", "Gluten-Free"]

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A").ignoresSafeArea()
            VStack(spacing: 24) {
                header
                GlassCard(cornerRadius: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L("select_preferences"))
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.white)
                        Wrap(alignment: .leading, spacing: 10) {
                            ForEach(options, id: \.self) { item in
                                TagView(text: item, isSelected: selected.contains(item)) {
                                    if selected.contains(item) {
                                        selected.remove(item)
                                    } else {
                                        selected.insert(item)
                                    }
                                }
                            }
                        }
                    }
                }
                NeoButton(title: String(localized: "save_profile")) {
                    onFinished()
                }
                Spacer()
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("health_diet"))
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundColor(.white)
            Text(L("health_diet_subtitle"))
                .font(.system(.body, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

