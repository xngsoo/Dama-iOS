//
//  UserService.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  Firestore /users/{uid} 컬렉션에 대한 CRUD.

import Foundation
import FirebaseFirestore

final class UserService {
    
    static let shared = UserService()
    private init() {}
    
    // MARK: - Read
    
    func fetchUser(uid: String) async throws -> User? {
        let snapshot = try await FirestoreCollection.user(uid).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: User.self)
    }
    
    // MARK: - Create / Upsert
    
    /// 신규 가입 시 호출. 이미 존재하면 그대로 반환.
    @discardableResult
    func createUserIfNeeded(uid: String, email: String?, name: String) async throws -> User {
        if let existing = try await fetchUser(uid: uid) {
            return existing
        }
        let newUser = User.new(uid: uid, email: email, name: name)
        try FirestoreCollection.user(uid).setData(from: newUser)
        return newUser
    }
    
    // MARK: - Update
    
    func updateName(uid: String, name: String) async throws {
        try await FirestoreCollection.user(uid).updateData([
            "name": name,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
    
    func updateFCMToken(uid: String, token: String) async throws {
        try await FirestoreCollection.user(uid).updateData([
            "fcmToken": token,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
}
