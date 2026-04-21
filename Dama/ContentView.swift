//
//  ContentView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//
//  AuthState에 따라 Splash / Login / Main 화면으로 분기.
//  Phase 3에서 @StateObject AuthViewModel로 교체 예정.
//  AuthState + @AppStorage(hasCompletedOnboarding) 조합으로 라우팅.

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject private var auth: AuthViewModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    /// Splash 최소 노출 시간 동안만 launching 유지.
    /// SplashView가 onComplete 호출하면 false → 실제 authState로 분기.
    @State private var isSplashing = true
    
    var body: some View {
        Group {
            if isSplashing {
                SplashView {
                    isSplashing = false
                }
            } else {
                routedView
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isSplashing)
        .animation(.easeInOut(duration: 0.35), value: auth.authState)
    }
    
    @ViewBuilder
    private var routedView: some View {
        switch auth.authState {
        case .launching:
            // Auth Listener 초기 동기화 중
            ProgressView()
                .tint(.damaCoral)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.damaCream.ignoresSafeArea())
            
        case .onboarding, .unauthenticated:
            if !hasCompletedOnboarding {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            } else {
                LoginView()
            }
            
        case .authenticated:
            MainPlaceholderView()
        }
    }
}

// MARK: - Main Placeholder (Phase 6에서 대체)

private struct MainPlaceholderView: View {
    @EnvironmentObject private var auth: AuthViewModel
    
    var body: some View {
        ZStack {
            Color.damaCream.ignoresSafeArea()
            
            VStack(spacing: DamaSpacing.lg) {
                Text("환영합니다")
                    .font(.damaDisplay)
                    .foregroundColor(.damaInk)
                
                if let name = auth.currentUser?.name {
                    Text("\(name)님")
                        .font(.damaSubheadline)
                        .foregroundStyle(.damaInkMuted)
                }
                
                Text("홈 화면은 Phase 6에서 만들어질 거예요")
                    .font(.damaBody)
                    .foregroundColor(.damaInkMuted)
                
                DamaButton("로그아웃", variant: .text) {
                    auth.signOut()
                }
                .padding(.top, DamaSpacing.xl)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
