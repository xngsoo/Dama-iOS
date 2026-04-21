//
//  DamaApp.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//

import SwiftUI
import KakaoSDKAuth
@main
struct DamaApp: App {
    
    /// UIKit AppDelegate 브리지.
    /// Firebase 초기화 및 푸시 알림 처리는 AppDelegate.swift에서 수행.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    
    /* 온보딩 강제 초기화 (테스트용)
    init() {
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }
    */
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .onOpenURL { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                }
        }
    }
}
