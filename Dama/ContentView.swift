//
//  ContentView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//
//  AuthState에 따라 Splash / Login / Main 화면으로 분기.
//  Phase 3에서 @StateObject AuthViewModel로 교체 예정.
//  AuthState + @AppStorage(hasCompletedOnboarding) 조합으로 라우팅.
//  dama — Root View (Auth Flow Router)

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject private var auth: AuthViewModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
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
            HomeView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
