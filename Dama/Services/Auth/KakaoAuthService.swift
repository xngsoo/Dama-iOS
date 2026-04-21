//
//  KakaoAuthService.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  플로우:
//   1. KakaoSDK로 로그인 (카카오톡 앱 우선, 없으면 계정 로그인)
//   2. 받은 access token을 Cloud Function `kakaoSignIn`에 전달
//   3. 서버가 반환한 Firebase custom token으로 FirebaseAuth 로그인
//
//  Firestore User 문서는 서버 측에서 이미 upsert된 상태이므로
//  클라이언트는 signIn 직후 `UserService.fetchUser`만 하면 됨.

import Foundation
import FirebaseAuth
import FirebaseFunctions
import KakaoSDKAuth
import KakaoSDKUser

@MainActor
final class KakaoAuthService {
    
    static let shared = KakaoAuthService()
    private init() {}
    
    private lazy var functions: Functions = {
        Functions.functions(region: "asia-northeast3")
    }()
    
    // MARK: - Sign In
    
    /// Kakao로 로그인하고 Firebase User까지 반환.
    func signIn() async throws -> User {
        
        // 1. Kakao access token 획득
        let kakaoToken = try await acquireKakaoAccessToken()
        
        // 2. Cloud Function 호출 → Firebase custom token 수신
        let firebaseToken = try await requestFirebaseCustomToken(kakaoAccessToken: kakaoToken)
        
        // 3. Firebase Auth 로그인
        let result: AuthDataResult
        do {
            result = try await Auth.auth().signIn(withCustomToken: firebaseToken)
        } catch {
            throw AuthError.signInFailed(error)
        }
        
        // 4. Firestore User 문서 fetch (서버에서 이미 upsert됨)
        let uid = result.user.uid
        do {
            guard let user = try await UserService.shared.fetchUser(uid: uid) else {
                throw AuthError.userNotFound
            }
            return user
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.firestoreSync(error)
        }
    }
    
    // MARK: - Kakao SDK
    
    /// 카카오톡 앱 설치 여부에 따라 로그인 방식 자동 선택.
    private func acquireKakaoAccessToken() async throws -> String {
        let oauthToken: OAuthToken
        do {
            if UserApi.isKakaoTalkLoginAvailable() {
                oauthToken = try await loginWithKakaoTalk()
            } else {
                oauthToken = try await loginWithKakaoAccount()
            }
        } catch {
            throw AuthError.kakaoSDKError(error)
        }
        
        guard !oauthToken.accessToken.isEmpty else {
            throw AuthError.kakaoTokenMissing
        }
        return oauthToken.accessToken
    }
    
    /// KakaoSDK의 콜백 기반 API를 async/await로 래핑.
    private func loginWithKakaoTalk() async throws -> OAuthToken {
        try await withCheckedThrowingContinuation { continuation in
            UserApi.shared.loginWithKakaoTalk { token, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let token = token {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: AuthError.kakaoTokenMissing)
                }
            }
        }
    }
    
    private func loginWithKakaoAccount() async throws -> OAuthToken {
        try await withCheckedThrowingContinuation { continuation in
            UserApi.shared.loginWithKakaoAccount { token, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let token = token {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: AuthError.kakaoTokenMissing)
                }
            }
        }
    }
    
    // MARK: - Cloud Function Call
    
    private func requestFirebaseCustomToken(kakaoAccessToken: String) async throws -> String {
        do {
            let callable = functions.httpsCallable("kakaoSignIn")
            let result = try await callable.call(["accessToken": kakaoAccessToken])
            
            guard let data = result.data as? [String: Any],
                  let token = data["firebaseToken"] as? String else {
                throw AuthError.functionsCallFailed(
                    NSError(domain: "KakaoAuth", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "응답 형식이 올바르지 않습니다."
                    ])
                )
            }
            return token
            
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.functionsCallFailed(error)
        }
    }
    
    // MARK: - Sign Out
    
    /// Kakao SDK 로그아웃. Firebase 로그아웃은 AuthService가 담당.
    func logoutKakaoSession() async {
        guard AuthApi.hasToken() else { return }
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            UserApi.shared.logout { _ in
                continuation.resume()
            }
        }
    }
}
