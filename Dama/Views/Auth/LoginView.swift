//
//  LoginView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//
//  Apple · Kakao 로그인 옵션 제공.
//  실제 인증 로직은 Phase 3(AuthService)에서 구현.
//  현재는 버튼 탭 시 onSuccess 콜백만 호출.

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    
    let onSuccess: () -> Void
    
    var body: some View {
        ZStack {
            Color.damaCream.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                Spacer()
                
                // MARK: Brand
                VStack(spacing: DamaSpacing.sm) {
                    Text("담아")
                        .font(.damaDisplay)
                        .foregroundColor(.damaInk)
                    
                    Text("우리끼리만 보는\n작고 따스한 기록")
                        .font(.damaSubheadline)
                        .foregroundColor(.damaInkMuted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                Spacer()
                
                // MARK: Auth Buttons
                VStack(spacing: DamaSpacing.md) {
                    
                    // Apple Sign In (네이티브 컴포넌트)
                    SignInWithAppleButton(
                        .continue,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: handleAppleResult
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .clipShape(Capsule())
                    
                    // Kakao Login (커스텀, 브랜드 컬러 준수)
                    Button(action: handleKakaoTap) {
                        HStack(spacing: DamaSpacing.sm) {
                            Image(systemName: "bubble.left.fill")
                                .font(.system(size: 15, weight: .semibold))
                            Text("카카오로 계속하기")
                                .font(.damaLabel)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .foregroundColor(kakaoTextColor)
                        .background(kakaoYellow)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(_LoginButtonPress())
                }
                .padding(.horizontal, DamaSpacing.xl)
                
                // MARK: Terms
                Text("계속 진행하면 서비스 이용약관과\n개인정보 처리방침에 동의하게 됩니다.")
                    .font(.damaMicro)
                    .foregroundColor(.damaInkSubtle)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.top, DamaSpacing.lg)
                    .padding(.bottom, DamaSpacing.xl)
            }
        }
    }
    
    // MARK: - Fixed Kakao Brand Colors (mode-invariant)
    
    private let kakaoYellow = Color(red: 254/255, green: 229/255, blue: 0/255)
    private let kakaoTextColor = Color(red: 25/255, green: 25/255, blue: 25/255)
    
    // MARK: - Handlers (stub — Phase 3에서 실제 구현)
    
    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            print("🍎 Apple 로그인 성공 — user: \(auth.credential)")
            // TODO: Phase 3에서 FirebaseAuth 연동
            onSuccess()
        case .failure(let error):
            print("🍎 Apple 로그인 실패: \(error.localizedDescription)")
        }
    }
    
    private func handleKakaoTap() {
        print("💬 Kakao 로그인 탭 (stub — Phase 3에서 KakaoSDK 연동)")
        // TODO: Phase 3에서 KakaoSDK + FirebaseAuth 연동
        onSuccess()
    }
}

// MARK: - Press Animation

private struct _LoginButtonPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Light") {
    LoginView(onSuccess: { })
}

#Preview("Dark") {
    LoginView(onSuccess: { })
        .preferredColorScheme(.dark)
}
