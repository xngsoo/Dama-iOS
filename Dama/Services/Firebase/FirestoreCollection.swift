//
//  FirestoreCollection.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  컬렉션 경로 문자열을 한 곳에서 관리하기 위한 헬퍼.
//  ⚠️ 모든 서비스는 raw Firestore.firestore() 호출 대신 이 enum 사용.
//  dama — Firestore Collection References

import FirebaseFirestore

enum FirestoreCollection {
    
    // MARK: - Top-level
    static var users: CollectionReference {
        Firestore.firestore().collection("users")
    }
    
    static var groups: CollectionReference {
        Firestore.firestore().collection("groups")
    }
    
    static var inviteCodes: CollectionReference {
        Firestore.firestore().collection("inviteCodes")
    }
    
    // MARK: - Subcollections
    static func members(groupId: String) -> CollectionReference {
        groups.document(groupId).collection("members")
    }
    
    static func photos(groupId: String) -> CollectionReference {
        groups.document(groupId).collection("photos")
    }
    
    static func comments(groupId: String, photoId: String) -> CollectionReference {
        photos(groupId: groupId).document(photoId).collection("comments")
    }
    
    // MARK: - Document refs
    static func user(_ uid: String) -> DocumentReference {
        users.document(uid)
    }
    
    static func group(_ groupId: String) -> DocumentReference {
        groups.document(groupId)
    }
    
    static func inviteCode(_ code: String) -> DocumentReference {
        inviteCodes.document(code)
    }
}
