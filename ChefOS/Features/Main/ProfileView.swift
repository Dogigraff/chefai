import SwiftUI

struct ProfileView: View {
    let profile: UserProfile?
    @EnvironmentObject private var languageManager: LanguageManager

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A").ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    heroCard
                    statsCard
                    settingsCard
                    Spacer(minLength: 60)
                }
                .padding()
            }
        }
    }

    private var heroCard: some View {
        GlassCard(cornerRadius: 24) {
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                    )
                VStack(alignment: .leading, spacing: 6) {
                Text(profileName)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                Text(String(localized: "create_profile_subtitle"))
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(.body, design: .rounded))
                }
                Spacer()
            }
        }
    }

    private var statsCard: some View {
        GlassCard(cornerRadius: 20) {
            HStack {
                statBlock(title: "Cooked", value: "24")
                Divider().background(Color.white.opacity(0.1))
                statBlock(title: "Favorites", value: "12")
                Divider().background(Color.white.opacity(0.1))
                statBlock(title: "Plans", value: "6")
            }
        }
    }

    private var settingsCard: some View {
        GlassCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Settings")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(.white)
                settingRow(icon: "shield", title: "Medical Profile", value: medicalSummary)
                settingRow(icon: "fork.knife", title: "Equipment", value: equipmentSummary)
                settingRow(icon: "bell", title: "Notifications", value: "Enabled")
                settingRow(icon: "paintbrush", title: "Appearance", value: "Dark")
                languagePickerRow
            }
        }
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack {
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundColor(.white)
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    private func settingRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.neoAccent)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(.white)
                    .font(.system(.body, design: .rounded))
                Text(value)
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(.footnote, design: .rounded))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.vertical, 6)
    }

    private var languagePickerRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "language_picker_title"))
                .foregroundColor(.white)
                .font(.system(.body, design: .rounded).weight(.semibold))
            Picker("", selection: Binding(
                get: { languageManager.currentLanguage },
                set: { languageManager.setLanguage($0) }
            )) {
                ForEach(LanguageManager.AppLanguage.allCases) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.top, 8)
    }

    private var profileName: String {
        if let name = profile?.religion.rawValue, name != "None" {
            return "Chef - \(name)"
        }
        return "Chef"
    }

    private var medicalSummary: String {
        let meds = profile?.medicalConditions.map(\.rawValue) ?? []
        return meds.isEmpty ? "No constraints" : meds.joined(separator: ", ")
    }

    private var equipmentSummary: String {
        let eq = profile?.equipment.map(\.rawValue) ?? []
        return eq.isEmpty ? "Not set" : "\(eq.count) items"
    }
}

