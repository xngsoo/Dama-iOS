//
//  PhotoDetailViewModel.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  dama — Photo Detail Screen State

import Foundation
import FirebaseFirestore
import Combine

@MainActor
final class PhotoDetailViewModel: ObservableObject {
    
    @Published var photo: Photo
    @Published private(set) var errorMessage: String?
    @Published private(set) var isDeleted = false
    
    private var listener: ListenerRegistration?
    
    init(photo: Photo) {
        self.photo = photo
    }
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - Listen
    
    func startListening() {
        guard listener == nil, let photoId = photo.id else { return }
        
        listener = PhotoService.shared.listenPhoto(
            groupId: photo.groupId,
            photoId: photoId,
            onUpdate: { [weak self] updated in
                Task { @MainActor in
                    guard let self else { return }
                    // 낙관적 업데이트로 바뀐 로컬 값이 서버 값으로 동기화됨.
                    // 서로 한쪽만 최신일 수 있어서 'updatedAt' 같은 기준으로 비교하는 게 이상적이지만,
                    // 대부분 서버 값이 최신이라 덮어쓰기로 충분.
                    self.photo = updated
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
    
    // MARK: - Like
    
    func toggleLike(uid: String) async {
        guard !uid.isEmpty else { return }
        let wasLiked = photo.isLikedBy(uid)
        
        applyLikeOptimistically(uid: uid, liked: !wasLiked)
        
        do {
            _ = try await PhotoService.shared.setLike(
                photo: photo,
                uid: uid,
                currentlyLiked: wasLiked
            )
        } catch {
            applyLikeOptimistically(uid: uid, liked: wasLiked)
            errorMessage = (error as? PhotoError)?.errorDescription
                ?? "좋아요에 실패했어요"
        }
    }
    
    private func applyLikeOptimistically(uid: String, liked: Bool) {
        var ids = photo.likedBy ?? []
        if liked {
            if !ids.contains(uid) {
                ids.append(uid)
                photo.likeCount += 1
            }
        } else {
            if let index = ids.firstIndex(of: uid) {
                ids.remove(at: index)
                photo.likeCount = max(0, photo.likeCount - 1)
            }
        }
        photo.likedBy = ids
    }
    
    // MARK: - Comment Count Sync
    
    func didChangeCommentCount(delta: Int) {
        photo.commentCount = max(0, photo.commentCount + delta)
    }
    
    // MARK: - Delete
    
    /// 사진 삭제. 성공 시 isDeleted=true로 부모 뷰가 dismiss 가능.
    @discardableResult
    func deletePhoto() async -> Bool {
        do {
            try await PhotoService.shared.deletePhoto(photo)
            // listener 해제 먼저 — deleted 문서에 대한 이벤트 방지
            stopListening()
            isDeleted = true
            return true
        } catch {
            errorMessage = (error as? PhotoError)?.errorDescription
                ?? "삭제에 실패했어요"
            return false
        }
    }
    
    // MARK: - Error
    
    func clearError() {
        errorMessage = nil
    }
}
