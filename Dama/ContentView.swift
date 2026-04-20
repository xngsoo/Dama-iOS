//
//  ContentView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//
//  AuthState에 따라 Splash / Login / Main 화면으로 분기.
//  Phase 3에서 @StateObject AuthViewModel로 교체 예정.

import SwiftUI

struct ContentView: View {
    
    @State private var authState: AuthState = .launching
    
    var body: some View {
        Group {
            switch authState {
            case .launching:
                SplashView {
                    authState = .unauthenticated
                }
                
            case .onboarding:
                // Phase 5b에서 구현
                Text("Onboarding (Phase 5b)")
                
            case .unauthenticated:
                LoginView {
                    authState = .authenticated
                }
                
            case .authenticated:
                // Phase 6에서 실제 홈 화면으로 교체
                MainPlaceholderView {
                    authState = .unauthenticated  // 임시 로그아웃 버튼용
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: authState)
    }
}

// MARK: - Main Placeholder (Phase 6에서 대체)

private struct MainPlaceholderView: View {
    let onLogout: () -> Void
    
    var body: some View {
        ZStack {
            Color.damaCream.ignoresSafeArea()
            
            VStack(spacing: DamaSpacing.lg) {
                Text("환영합니다")
                    .font(.damaDisplay)
                    .foregroundColor(.damaInk)
                
                Text("홈 화면은 Phase 6에서 만들어질 거예요")
                    .font(.damaBody)
                    .foregroundColor(.damaInkMuted)
                
                DamaButton("로그아웃", variant: .text) {
                    onLogout()
                }
                .padding(.top, DamaSpacing.xl)
            }
        }
    }
}

#Preview {
    ContentView()
}
