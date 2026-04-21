//
//  AuthError.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  dama — Auth Domain Errors

import Foundation

enum AuthError: LocalizedError {
    case userNotFound
    case appleCredentialMissing
    case appleNonceFailure
    case kakaoTokenMissing
    case kakaoSDKError(Error)
    case functionsCallFailed(Error)
    case firestoreSync(Error)
    case signInFailed(Error)
    case signOutFailed(Error)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "사용자 정보를 찾을 수 없어요"
        case .appleCredentialMissing:
            return "Apple 로그인 정보를 받아오지 못했어요"
        case .appleNonceFailure:
            return "Apple 로그인 보안 검증에 실패했어요"
        case .kakaoTokenMissing:
            return "카카오 토큰을 받아오지 못했어요"
        case .kakaoSDKError:
            return "카카오 로그인에 실패했어요"
        case .functionsCallFailed:
            return "서버와 통신에 실패했어요"
        case .firestoreSync:
            return "사용자 정보 저장에 실패했어요"
        case .signInFailed:
            return "로그인에 실패했어요"
        case .signOutFailed:
            return "로그아웃에 실패했어요"
        case .unknown:
            return "예기치 못한 문제가 발생했어요"
        }
    }
}
