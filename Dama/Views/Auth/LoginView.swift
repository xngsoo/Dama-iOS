//
//  LoginView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//
//  Apple Sign In은 Phase 3a에서 실제 동작.
//  Kakao는 Phase 3b에서 연동 예정 (지금은 stub 유지).

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var auth: AuthViewModel
    
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
                    
                    // Apple Sign In
                    SignInWithAppleButton(
                        .continue,
                        onRequest: { request in
                            auth.prepareAppleSignIn(request)
                        },
                        onCompletion:  { result in
                            Task {
                                await auth.handleAppleResult(result)
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .clipShape(Capsule())
                    .disabled(auth.isLoading)
                    
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
                    .disabled(auth.isLoading)
                    
                    if auth.isLoading {
                        ProgressView()
                            .tint(.damaCoral)
                            .padding(.top, DamaSpacing.xs)
                    }
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
        .alert("로그인 실패", isPresented: errorBinding) {
            Button("확인", role: .cancel) {
                auth.clearError()
            }
        } message: {
            Text(auth.errorMessage ?? "")
        }
    }
    
    // MARK: - Binding
    
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { auth.errorMessage != nil },
            set: { if !$0 { auth.clearError() } }
        )
    }
    
    // MARK: - Kakao (Phase 3b stub 유지)
    
    private let kakaoYellow = Color(red: 254/255, green: 229/255, blue: 0/255)
    private let kakaoTextColor = Color(red: 25/255, green: 25/255, blue: 25/255)
    
    private func handleKakaoTap() {
        Task {
            await auth.signInWithKakao()
        }
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
    LoginView()
        .environmentObject(AuthViewModel())
}

#Preview("Dark") {
    LoginView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}
