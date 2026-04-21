//
//  CommentsViewModel.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  dama — Comments State with realtime listener

import Foundation
import FirebaseFirestore
import Combine

@MainActor
final class CommentsViewModel: ObservableObject {
    
    // MARK: - Published
    
    @Published private(set) var comments: [Comment] = []
    @Published private(set) var isSubmitting = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - Private
    
    private let photo: Photo
    private var listener: ListenerRegistration?
    
    // MARK: - Init / Deinit
    
    init(photo: Photo) {
        self.photo = photo
    }
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - Listening
    
    func startListening() {
        guard listener == nil, let photoId = photo.id else { return }
        
        listener = CommentService.shared.listenComments(
            groupId: photo.groupId,
            photoId: photoId,
            onUpdate: { [weak self] comments in
                Task { @MainActor in
                    self?.comments = comments
                }
            },
            onError: { [weak self] error in
                Task { @MainActor in
                    self?.errorMessage = error.localizedDescription
                }
            }
        )
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    // MARK: - Add
    /// 댓글 등록. 성공 시 true, 실패 시 false 반환.
    @discardableResult
    func submit(text: String, author: User) async -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSubmitting else { return false }
        
        isSubmitting = true
        defer { isSubmitting = false }
        
        do {
            _ = try await CommentService.shared.addComment(
                text: trimmed,
                photo: photo,
                author: author
            )
            return true
        } catch {
            errorMessage = (error as? PhotoError)?.errorDescription
            ?? "댓글을 남기지 못했어요"
            return false
        }
    }
    
    // MARK: - Delete
    @discardableResult
    func delete(_ comment: Comment) async -> Bool {
        do {
            try await CommentService.shared.deleteComment(comment: comment, photo: photo)
            return true
        } catch {
            errorMessage = (error as? PhotoError)?.errorDescription
            ?? "댓글을 삭제하지 못했어요"
            return false
        }
    }
    
    // MARK: - Error
    
    func clearError() {
        errorMessage = nil
    }
}
