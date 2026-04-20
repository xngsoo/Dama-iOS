//
//  User.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//
//  Firestore: /users/{uid}
//  id 는 Firebase Auth UID 와 동일.

import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable, Hashable {
    
    @DocumentID var id: String?
    
    var email: String?
    var name: String
    var profileImageURL: String?
    var groupIds: [String]            // 소속 그룹 (denormalized, 빠른 조회용)
    var fcmToken: String?             // Rewind 푸시 수신용
    
    @ServerTimestamp var createdAt: Timestamp?
    var updatedAt: Timestamp?
    
    // MARK: - Convenience
    
    /// Auth 직후 신규 유저 생성용 팩토리
    static func new(uid: String, email: String?, name: String) -> User {
        User(
            id: uid,
            email: email,
            name: name,
            profileImageURL: nil,
            groupIds: [],
            fcmToken: nil
        )
    }
}
