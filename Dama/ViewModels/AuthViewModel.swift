//
//  AuthViewModel.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  Firebase Auth 상태를 관찰하고, AuthState enum으로 변환해 UI에 전달.
//  ContentView는 이 ViewModel만 보면 됨.

import Foundation
import FirebaseAuth
import AuthenticationServices
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var authState: AuthState = .launching
    @Published private(set) var currentUser: User?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading = false
    
    // MARK: - Private
    
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    
    // MARK: - Init
    
    init() {
        startListening()
    }
    
    deinit {
        if let handle = authListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - State Listener
    
    private func startListening() {
        authListenerHandle = AuthService.shared.addStateListener { [weak self] firebaseUser in
            guard let self else { return }
            Task { @MainActor in
                await self.handleAuthChange(firebaseUser)
            }
        }
    }
    
    private func handleAuthChange(_ firebaseUser: FirebaseAuth.User?) async {
        guard let firebaseUser else {
            currentUser = nil
            authState = .unauthenticated
            return
        }
        
        // Firestore User 문서 로드
        do {
            let user = try await UserService.shared.fetchUser(uid: firebaseUser.uid)
            currentUser = user
            authState = .authenticated
        } catch {
            #if DEBUG
            print("⚠️ User 문서 로드 실패: \(error.localizedDescription)")
            #endif
            // Firestore 동기화 실패 시에도 UI는 진입시키되 currentUser는 nil 유지
            authState = .authenticated
        }
    }
    
    // MARK: - Apple Sign In
    
    /// LoginView에서 ASAuthorizationAppleIDRequest를 만들기 직전 호출.
    func prepareAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = AppleSignInCoordinator.randomNonce()
        AppleSignInCoordinator.currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = AppleSignInCoordinator.sha256(nonce)
    }
    
    /// SignInWithAppleButton의 onCompletion에서 호출.
    func handleAppleResult(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        defer { isLoading = false }
        
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = AuthError.appleCredentialMissing.errorDescription
                return
            }
            do {
                let user = try await AuthService.shared.signInWithApple(credential: credential)
                currentUser = user
                // authState 변경은 listener가 자동 처리
            } catch let error as AuthError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = AuthError.unknown(error).errorDescription
            }
            
        case .failure(let error):
            // 사용자가 취소한 경우는 에러 표시 안 함
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = AuthError.signInFailed(error).errorDescription
            }
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        do {
            try AuthService.shared.signOut()
            // listener가 .unauthenticated로 자동 전환
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = AuthError.unknown(error).errorDescription
        }
    }
    
    // MARK: - Error Dismissal
    
    func clearError() {
        errorMessage = nil
    }
}
