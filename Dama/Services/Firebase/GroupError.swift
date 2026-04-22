//
//  GroupError.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  dama — Group Domain Errors

import Foundation

enum GroupError: LocalizedError {
    case notAuthenticated
    case notAuthorized
    case groupNotFound
    case inviteCodeNotFound
    case alreadyMember
    case groupIsFull
    case notAMember
    case cannotLeaveAsOwner
    case firestoreFailure(Error)
    case codeGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "로그인이 필요해요"
        case .notAuthorized:
            return "이 작업을 수행할 권한이 없어요"
        case .groupNotFound:
            return "그룹을 찾을 수 없어요"
        case .inviteCodeNotFound:
            return "초대 코드를 찾을 수 없어요"
        case .alreadyMember:
            return "이미 참여한 그룹이에요"
        case .groupIsFull:
            return "그룹이 가득 찼어요 (최대 10명)"
        case .notAMember:
            return "그룹 멤버가 아니에요"
        case .cannotLeaveAsOwner:
            return "그룹장은 나가기 전에 다른 멤버에게 권한을 넘겨주세요"
        case .firestoreFailure:
            return "정보를 불러오는 데 실패했어요"
        case .codeGenerationFailed:
            return "초대 코드 생성에 실패했어요. 다시 시도해주세요"
        }
    }
}
