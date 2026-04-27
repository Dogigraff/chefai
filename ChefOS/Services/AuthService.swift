import Foundation

protocol AuthService {
    func signInAnonymously() async -> Bool
}

final class MockAuthService: AuthService {
    func signInAnonymously() async -> Bool {
        return true
    }
}

#if canImport(FirebaseAuth)
import FirebaseAuth

final class FirebaseAuthService: AuthService {
    func signInAnonymously() async -> Bool {
        do {
            _ = try await Auth.auth().signInAnonymously()
            return true
        } catch {
            print("Firebase anonymous auth failed: \(error.localizedDescription)")
            return false
        }
    }
}
#endif

