//
//  HomeViewModel.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//

import Foundation
import FirebaseFirestore
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    
    // MARK: - Published
    
    @Published private(set) var groups: [DamaGroup] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - Join Result
    
    enum JoinResult {
        case success
        case notFound
        case alreadyMember
        case full
        case failed
    }
    
    // MARK: - Load
    
    func loadGroups(for uid: String?) async {
        guard let uid = uid else {
            groups = []
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            groups = try await GroupService.shared.fetchGroups(for: uid)
        } catch let error as GroupError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = GroupError.firestoreFailure(error).errorDescription
        }
    }
    
    func refresh(for uid: String?) async {
        await loadGroups(for: uid)
    }
    
    // MARK: - Create
    
    @discardableResult
    func createGroup(
        name: String,
        coverEmoji: String?,
        owner: User
    ) async -> DamaGroup? {
        do {
            let new = try await GroupService.shared.createGroup(
                name: name,
                coverEmoji: coverEmoji,
                owner: owner
            )
            groups.insert(new, at: 0)
            return new
        } catch let error as GroupError {
            errorMessage = error.errorDescription
            return nil
        } catch {
            errorMessage = GroupError.firestoreFailure(error).errorDescription
            return nil
        }
    }
    
    // MARK: - Join
    
    func joinGroup(inviteCode: String, user: User) async -> JoinResult {
        do {
            let joined = try await GroupService.shared.joinGroup(
                inviteCode: inviteCode,
                user: user
            )
            // 리스트 최상단에 추가 (이미 있으면 중복 방지)
            if !groups.contains(where: { $0.id == joined.id }) {
                groups.insert(joined, at: 0)
            }
            return .success
        } catch GroupError.inviteCodeNotFound {
            return .notFound
        } catch GroupError.alreadyMember {
            return .alreadyMember
        } catch GroupError.groupIsFull {
            return .full
        } catch {
            errorMessage = (error as? GroupError)?.errorDescription
                ?? GroupError.firestoreFailure(error).errorDescription
            return .failed
        }
    }
    
    /// 특정 그룹의 photoCount를 로컬에서 1 감소.
    func didDeletePhoto(groupId: String) {
        guard let index = groups.firstIndex(where: { $0.id == groupId }) else { return }
        groups[index].photoCount = max(0, groups[index].photoCount - 1)
    }
    
    // MARK: - Local Sync (사진 업로드 등 자식 화면의 변경 반영)
    
    /// 특정 그룹의 photoCount와 lastPhotoAt을 로컬에서 갱신.
    /// 홈 리스트에서 즉시 "사진 N장 · 방금"으로 보이도록.
    func didUploadPhotos(groupId: String, count: Int) {
        guard count > 0,
              let index = groups.firstIndex(where: { $0.id == groupId }) else {
            return
        }
        
        groups[index].photoCount += count
        let now = Timestamp(date: Date())
        groups[index].lastPhotoAt = now
        groups[index].updatedAt = now
        
        // updatedAt이 방금이 됐으니 리스트 최상단으로 이동 (서버 정렬과 일치)
        if index != 0 {
            let moved = groups.remove(at: index)
            groups.insert(moved, at: 0)
        }
    }
    
    // MARK: - Error Dismissal
    func clearError() {
        errorMessage = nil
    }
}
