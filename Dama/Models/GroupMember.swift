//
//  GroupMember.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//
//  Firestore: /groups/{groupId}/members/{userId}
//  doc id 는 userId 와 동일하게 유지 (중복 가입 방지).

import Foundation
import FirebaseFirestore

struct GroupMember: Codable, Identifiable, Hashable {
    
    @DocumentID var id: String?       // = userId
    
    var userId: String
    var role: Role
    var displayName: String           // denormalized from User.name
    var profileImageURL: String?      // denormalized
    
    @ServerTimestamp var joinedAt: Timestamp?
    
    // MARK: - Role
    
    enum Role: String, Codable {
        case owner     // 그룹 생성자 (1명)
        case member    // 일반 멤버
    }
    
    // MARK: - Computed
    
    var isOwner: Bool { role == .owner }
    
    // MARK: - Factory
    
    static func new(from user: User, groupId: String, role: Role = .member) -> GroupMember {
        GroupMember(
            id: user.id,
            userId: user.id ?? "",
            role: role,
            displayName: user.name,
            profileImageURL: user.profileImageURL
        )
    }
}
