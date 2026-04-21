//
//  AppleSignInCoordinator.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  Apple → Firebase 로그인을 위한 nonce 생성/SHA256 해싱 헬퍼.
//  Firebase 공식 가이드 기반 표준 구현.

import Foundation
import CryptoKit
import AuthenticationServices

enum AppleSignInCoordinator {
    
    /// 현재 진행 중인 nonce. ASAuthorizationAppleIDRequest 직전에 set,
    /// credential 검증 시 다시 사용.
    static var currentNonce: String?
    
    // MARK: - Nonce Generation
    
    /// 32바이트 랜덤 문자열 생성. Firebase가 요구하는 영숫자 + 일부 특수문자 집합.
    static func randomNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        
        while remaining > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if status != errSecSuccess {
                    fatalError("SecRandomCopyBytes failed with OSStatus \(status)")
                }
                return random
            }
            
            randoms.forEach { byte in
                if remaining == 0 { return }
                if byte < charset.count {
                    result.append(charset[Int(byte)])
                    remaining -= 1
                }
            }
        }
        return result
    }
    
    /// Apple에 보내는 SHA256 해시 (raw nonce는 Firebase에 전달).
    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
