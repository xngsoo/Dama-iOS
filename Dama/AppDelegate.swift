//
//  AppDelegate.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//

import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate {
    
    // MARK: - Launch
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // 1. Firebase 초기화
        FirebaseApp.configure()
        
        // 2. 알림 & Messaging delegate 등록
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        #if DEBUG
        print("🔥 Firebase configured — project: \(FirebaseApp.app()?.options.projectID ?? "nil")")
        #endif
        
        return true
    }
    
    // MARK: - APNs Token
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        #if DEBUG
        print("⚠️ APNs 등록 실패: \(error.localizedDescription)")
        #endif
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    /// foreground 상태에서도 알림 배너 표시
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .badge, .sound]
    }
    
    /// 알림 탭 시 (Rewind 딥링크 처리는 Phase 7에서 확장)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        #if DEBUG
        print("📬 알림 탭됨 payload: \(userInfo)")
        #endif
    }
}

// MARK: - MessagingDelegate (FCM)
extension AppDelegate: MessagingDelegate {
    
    /// FCM 토큰 발급·갱신 시 호출
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        
        #if DEBUG
        print("🔥 FCM Token: \(token)")
        #endif
        
        // TODO: Phase 3에서 이 토큰을 Firestore users/{uid}/fcmToken 에 저장
    }
}
