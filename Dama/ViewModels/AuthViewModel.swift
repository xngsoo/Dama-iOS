//
//  AuthViewModel.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  Firebase Auth 상태를 관찰하고, AuthState enum으로 변환해 UI에 전달.
//  ContentView는 이 ViewModel만 보면 됨.
//  dama — Global Auth State

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
        
        do {
            let user = try await UserService.shared.fetchUser(uid: firebaseUser.uid)
            currentUser = user
            authState = .authenticated
        } catch {
            #if DEBUG
            print("⚠️ User 문서 로드 실패: \(error.localizedDescription)")
            #endif
            authState = .authenticated
        }
    }
    
    // MARK: - Apple Sign In
    
    func prepareAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = AppleSignInCoordinator.randomNonce()
        AppleSignInCoordinator.currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = AppleSignInCoordinator.sha256(nonce)
    }
    
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
            } catch let error as AuthError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = AuthError.unknown(error).errorDescription
            }
            
        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = AuthError.signInFailed(error).errorDescription
            }
        }
    }
    
    // MARK: - Kakao Sign In
    
    func signInWithKakao() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let user = try await KakaoAuthService.shared.signIn()
            currentUser = user
            // authState는 listener가 자동 전환
        } catch let error as AuthError {
            // 사용자 취소는 에러 표시 안 함 (KakaoSDK ClientFailureReason.Cancelled)
            if !isKakaoUserCancelled(error) {
                errorMessage = error.errorDescription
            }
        } catch {
            errorMessage = AuthError.unknown(error).errorDescription
        }
    }
    
    private func isKakaoUserCancelled(_ error: AuthError) -> Bool {
        guard case .kakaoSDKError(let underlying) = error else { return false }
        // KakaoSDK는 취소 시 ClientFailed(-777) 같은 에러를 반환.
        // 에러 description에 "cancel"이 포함되면 취소로 간주.
        return underlying.localizedDescription.lowercased().contains("cancel")
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        Task {
            do {
                try await AuthService.shared.signOut()
            } catch let error as AuthError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = AuthError.unknown(error).errorDescription
            }
        }
    }
    
    // MARK: - Error Dismissal
    
    func clearError() {
        errorMessage = nil
    }
}
