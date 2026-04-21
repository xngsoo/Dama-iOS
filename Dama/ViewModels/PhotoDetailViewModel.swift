//
//  PhotoDetailViewModel.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  좋아요·댓글 상태를 관리. 댓글은 Phase 7a-②에서 추가.
//  낙관적 업데이트(optimistic update)로 즉각 반응.

import Foundation
import Combine

@MainActor
final class PhotoDetailViewModel: ObservableObject {
    
    @Published var photo: Photo
    @Published private(set) var errorMessage: String?
    
    init(photo: Photo) {
        self.photo = photo
    }
    
    // MARK: - Like
    func toggleLike(uid: String) async {
        guard !uid.isEmpty else { return }
        
        // 1. 판정은 딱 한 번 — 낙관적 업데이트 전의 상태 기준
        let wasLiked = photo.isLikedBy(uid)
        
        // 2. 낙관적 업데이트 먼저 (UI 즉시 반영)
        applyLikeOptimistically(uid: uid, liked: !wasLiked)
        
        // 3. 서버에는 "원래 상태 + 판정 결과"를 명시적으로 전달
        do {
            _ = try await PhotoService.shared.setLike(
                photo: photo,       // 낙관적 업데이트된 photo여도 상관없음 — liked 판정은 currentlyLiked로 전달되므로
                uid: uid,
                currentlyLiked: wasLiked  // 판정 당시 값 그대로
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
    /// 댓글이 추가/삭제됐을 때 로컬 photo.commentCount 갱신 (시트에서 호출).
    func didChangeCommentCount(delta: Int) {
        photo.commentCount = max(0, photo.commentCount + delta)
    }
    
    // MARK: - Error
    
    func clearError() {
        errorMessage = nil
    }
}
