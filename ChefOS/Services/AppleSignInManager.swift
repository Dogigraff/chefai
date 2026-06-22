import AuthenticationServices
import Foundation
import UIKit

final class AppleSignInManager: NSObject {
    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?
}

extension AppleSignInManager: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func startSignIn() async throws -> ASAuthorizationAppleIDCredential {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            continuation?.resume(returning: credential)
        } else {
            continuation?.resume(throwing: NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "No credential"]))
        }
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let window = scenes.flatMap(\.windows).first(where: { $0.isKeyWindow }) {
            return window
        }
        if let window = scenes.flatMap(\.windows).first {
            return window
        }
        return ASPresentationAnchor()
    }
}

