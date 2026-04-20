//
//  AuthState.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//
//  앱 최상위 라우팅에 쓰이는 상태 enum.
//  Phase 3에서 AuthViewModel이 Firebase 상태를 관찰하며 이 값을 업데이트합니다.

import Foundation

enum AuthState {
    case launching        // Splash 중
    case onboarding       // Onboarding (Phase 5b)
    case unauthenticated  // Login 화면
    case authenticated    // 메인 앱 진입
}
