//
//  CommentService.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  dama — Comment CRUD Service
//  실시간 snapshot listener 기반 구독 + 쓰기/삭제.

import Foundation
import FirebaseFirestore

@MainActor
final class CommentService {
    
    static let shared = CommentService()
    private init() {}
    
    // MARK: - Listener
    
    /// 사진의 댓글을 실시간 구독. 호출자는 반환된 registration의 remove()를 반드시 호출.
    func listenComments(
        groupId: String,
        photoId: String,
        onUpdate: @escaping ([Comment]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ListenerRegistration {
        return FirestoreCollection.comments(groupId: groupId, photoId: photoId)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    onError(error)
                    return
                }
                guard let snapshot = snapshot else {
                    onUpdate([])
                    return
                }
                let comments = snapshot.documents.compactMap { doc in
                    try? doc.data(as: Comment.self)
                }
                onUpdate(comments)
            }
    }
    
    // MARK: - Create
    
    /// 댓글 작성 + photo.commentCount 증가 (트랜잭션).
    func addComment(
        text: String,
        photo: Photo,
        author: User
    ) async throws -> Comment {
        guard let photoId = photo.id,
              let uid = author.id, !uid.isEmpty else {
            throw PhotoError.notAuthenticated
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw PhotoError.imageProcessingFailed  // 재사용 에러 — 메시지용
        }
        
        let commentRef = FirestoreCollection
            .comments(groupId: photo.groupId, photoId: photoId)
            .document()
        let commentId = commentRef.documentID
        
        let photoRef = FirestoreCollection
            .photos(groupId: photo.groupId)
            .document(photoId)
        
        let comment = Comment(
            id: commentId,
            photoId: photoId,
            groupId: photo.groupId,
            userId: uid,
            userName: author.name,
            userProfileImageURL: author.profileImageURL,
            text: trimmed
        )
        
        let db = Firestore.firestore()
        do {
            _ = try await db.runTransaction { transaction, errorPointer in
                do {
                    try transaction.setData(from: comment, forDocument: commentRef)
                    transaction.updateData([
                        "commentCount": FieldValue.increment(Int64(1)),
                    ], forDocument: photoRef)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
                return nil
            }
        } catch {
            throw PhotoError.firestoreFailure(error)
        }
        
        return comment
    }
    
    // MARK: - Delete
    
    func deleteComment(
        comment: Comment,
        photo: Photo
    ) async throws {
        guard let commentId = comment.id, let photoId = photo.id else {
            throw PhotoError.photoNotFound
        }
        
        let commentRef = FirestoreCollection
            .comments(groupId: photo.groupId, photoId: photoId)
            .document(commentId)
        let photoRef = FirestoreCollection
            .photos(groupId: photo.groupId)
            .document(photoId)
        
        let db = Firestore.firestore()
        do {
            _ = try await db.runTransaction { transaction, errorPointer in
                transaction.deleteDocument(commentRef)
                transaction.updateData([
                    "commentCount": FieldValue.increment(Int64(-1)),
                ], forDocument: photoRef)
                return nil
            }
        } catch {
            throw PhotoError.firestoreFailure(error)
        }
    }
}
