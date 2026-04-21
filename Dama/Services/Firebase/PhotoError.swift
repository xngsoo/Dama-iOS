//
//  PhotoError.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  dama — Photo Domain Errors

import Foundation

enum PhotoError: LocalizedError {
    case notAuthenticated
    case notAMember
    case imageProcessingFailed
    case uploadFailed(Error)
    case storageFailure(Error)
    case firestoreFailure(Error)
    case photoNotFound
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "로그인이 필요해요"
        case .notAMember:
            return "그룹 멤버가 아니에요"
        case .imageProcessingFailed:
            return "이미지를 처리하지 못했어요"
        case .uploadFailed:
            return "업로드에 실패했어요"
        case .storageFailure:
            return "파일 저장에 문제가 생겼어요"
        case .firestoreFailure:
            return "정보를 불러오지 못했어요"
        case .photoNotFound:
            return "사진을 찾을 수 없어요"
        case .unauthorized:
            return "이 작업을 수행할 권한이 없어요"
        }
    }
}
