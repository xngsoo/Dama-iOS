//
//  Comment.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//
//  Firestore: /groups/{groupId}/photos/{photoId}/comments/{commentId}

import Foundation
import FirebaseFirestore

struct Comment: Codable, Identifiable, Hashable {
    
    @DocumentID var id: String?
    
    var photoId: String
    var groupId: String
    var userId: String
    var userName: String              // denormalized
    var userProfileImageURL: String?
    
    var text: String
    
    @ServerTimestamp var createdAt: Timestamp?
    
    // MARK: - Factory
    
    static func new(
        photoId: String,
        groupId: String,
        from user: User,
        text: String
    ) -> Comment {
        Comment(
            photoId: photoId,
            groupId: groupId,
            userId: user.id ?? "",
            userName: user.name,
            userProfileImageURL: user.profileImageURL,
            text: text
        )
    }
}
