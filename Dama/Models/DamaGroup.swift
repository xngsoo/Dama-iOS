//
//  DamaGroup.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//
//  Firestore: /groups/{groupId}
//  SwiftUI.Group 충돌 회피를 위해 Dama prefix 적용.

import Foundation
import FirebaseFirestore

struct DamaGroup: Codable, Identifiable, Hashable {
    
    @DocumentID var id: String?
    
    var name: String
    var coverEmoji: String?           // 그룹 대표 이모지 (선택)
    var inviteCode: String            // 6자리, 대문자+숫자 (중복 가능 문자 제외)
    var ownerId: String               // 생성자 UID
    var memberIds: [String]           // 멤버 UID 목록 (max 10, denormalized)
    var memberCount: Int
    var photoCount: Int
    
    @ServerTimestamp var createdAt: Timestamp?
    var updatedAt: Timestamp?
    var lastPhotoAt: Timestamp?       // 최근 업로드 시각 (홈 정렬용)
    
    // MARK: - Constants
    
    static let maxMembers = 10
    static let inviteCodeLength = 6
    
    // MARK: - Computed
    
    var isFull: Bool { memberCount >= Self.maxMembers }
    
    func isOwner(_ userId: String) -> Bool { ownerId == userId }
    func isMember(_ userId: String) -> Bool { memberIds.contains(userId) }
    
    // MARK: - Factory
    
    /// 혼동되기 쉬운 O/0, 1/I/L 제외한 30자 집합에서 랜덤 추출.
    static func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
        return String((0..<inviteCodeLength).map { _ in chars.randomElement()! })
    }
    
    /// 새 그룹 생성 팩토리
    static func new(name: String, ownerId: String, coverEmoji: String? = nil) -> DamaGroup {
        DamaGroup(
            name: name,
            coverEmoji: coverEmoji,
            inviteCode: generateInviteCode(),
            ownerId: ownerId,
            memberIds: [ownerId],
            memberCount: 1,
            photoCount: 0
        )
    }
}
