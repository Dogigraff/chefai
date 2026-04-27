import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var name: String = ""
    @Published var isLoading: Bool = false

    func login() async -> Bool {
        isLoading = true
        defer { isLoading = false }
        try? await Task.sleep(nanoseconds: 600_000_000)
        return !email.isEmpty && !password.isEmpty
    }

    func register() async -> Bool {
        isLoading = true
        defer { isLoading = false }
        try? await Task.sleep(nanoseconds: 600_000_000)
        return !email.isEmpty && !password.isEmpty && !name.isEmpty
    }
}

