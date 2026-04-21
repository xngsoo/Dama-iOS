//
//  StoragePath.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  dama — Firebase Storage Path Helpers

import Foundation
import FirebaseStorage

enum StoragePath {
    
    private static var root: StorageReference {
        Storage.storage().reference()
    }
    
    // MARK: - Photo
    
    static func photoOriginal(groupId: String, photoId: String) -> StorageReference {
        root.child("groups/\(groupId)/photos/\(photoId).jpg")
    }
    
    static func photoThumbnail(groupId: String, photoId: String) -> StorageReference {
        root.child("groups/\(groupId)/thumbs/\(photoId).jpg")
    }
    
    // MARK: - Raw paths (Firestore Photo.storagePath에 저장되는 문자열)
    
    static func photoOriginalPath(groupId: String, photoId: String) -> String {
        "groups/\(groupId)/photos/\(photoId).jpg"
    }
    
    static func photoThumbnailPath(groupId: String, photoId: String) -> String {
        "groups/\(groupId)/thumbs/\(photoId).jpg"
    }
}
