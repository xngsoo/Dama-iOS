//
//  AuthService.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  Apple Sign In + Firebase Auth + Firestore User 문서 동기화.
//  Kakao 연동은 Phase 3b에서 추가.

import Foundation
import AuthenticationServices
import FirebaseAuth

@MainActor
final class AuthService {
    
    static let shared = AuthService()
    private init() {}
    
    // MARK: - Current State
    
    var currentUser: FirebaseAuth.User? {
        Auth.auth().currentUser
    }
    
    var isAuthenticated: Bool {
        currentUser != nil
    }
    
    // MARK: - Auth State Listener
    
    /// Firebase Auth 상태 변화 구독. ViewModel에서 사용.
    func addStateListener(_ handler: @escaping (FirebaseAuth.User?) -> Void) -> AuthStateDidChangeListenerHandle {
        Auth.auth().addStateDidChangeListener { _, user in
            handler(user)
        }
    }
    
    func removeStateListener(_ handle: AuthStateDidChangeListenerHandle) {
        Auth.auth().removeStateDidChangeListener(handle)
    }
    
    // MARK: - Apple Sign In
    
    /// Apple credential을 Firebase로 교환하고 Firestore User 문서 동기화.
    /// 반환값: Firestore에 저장된 User 도메인 객체.
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User {
        
        // 1. Nonce 검증
        guard let nonce = AppleSignInCoordinator.currentNonce else {
            throw AuthError.appleNonceFailure
        }
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.appleCredentialMissing
        }
        
        // 2. Firebase OAuth credential 구성
        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: tokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )
        
        // 3. Firebase 로그인
        let result: AuthDataResult
        do {
            result = try await Auth.auth().signIn(with: firebaseCredential)
        } catch {
            throw AuthError.signInFailed(error)
        }
        AppleSignInCoordinator.currentNonce = nil  // 1회용 소진
        
        // 4. Firestore User 동기화
        let uid = result.user.uid
        let email = result.user.email ?? credential.email
        let displayName = composeDisplayName(
            from: credential.fullName,
            firebaseName: result.user.displayName,
            fallback: email
        )
        
        do {
            return try await UserService.shared.createUserIfNeeded(
                uid: uid,
                email: email,
                name: displayName
            )
        } catch {
            throw AuthError.firestoreSync(error)
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw AuthError.signOutFailed(error)
        }
    }
    
    // MARK: - Helpers
    
    /// Apple은 첫 로그인에만 fullName을 줌. 우선순위: Apple → Firebase → email prefix → 기본값.
    private func composeDisplayName(
        from appleName: PersonNameComponents?,
        firebaseName: String?,
        fallback email: String?
    ) -> String {
        if let appleName, let formatted = formattedName(appleName), !formatted.isEmpty {
            return formatted
        }
        if let firebaseName, !firebaseName.isEmpty {
            return firebaseName
        }
        if let email, let prefix = email.split(separator: "@").first {
            return String(prefix)
        }
        return "담아 사용자"
    }
    
    private func formattedName(_ components: PersonNameComponents) -> String? {
        let formatter = PersonNameComponentsFormatter()
        formatter.style = .default
        let result = formatter.string(from: components)
        return result.isEmpty ? nil : result
    }
}
