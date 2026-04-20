//
//  Photo.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.

//  Firestore: /groups/{groupId}/photos/{photoId}
//  실제 이미지는 Firebase Storage에 저장, 경로(storagePath)만 기록.

import Foundation
import CoreGraphics
import FirebaseFirestore

struct Photo: Codable, Identifiable, Hashable {
    
    @DocumentID var id: String?
    
    var groupId: String
    var uploaderId: String
    var uploaderName: String          // denormalized from User.name
    
    var storagePath: String           // Storage 경로 (원본)
    var thumbnailPath: String?        // 썸네일 경로 (Cloud Function으로 생성)
    
    var caption: String?
    var width: Int
    var height: Int
    
    var likeCount: Int
    var commentCount: Int
    
    @ServerTimestamp var uploadedAt: Timestamp?
    var takenAt: Timestamp?           // EXIF 촬영 시각 (Rewind 계산에 사용)
    
    // MARK: - Computed
    
    var aspectRatio: CGFloat {
        guard height > 0 else { return 1 }
        return CGFloat(width) / CGFloat(height)
    }
    
    var isPortrait: Bool { aspectRatio < 1 }
}
