//
//  GroupSettingsViewModel.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/22/26.
//
//  dama — Group Settings State

import Foundation
import Combine

@MainActor
final class GroupSettingsViewModel: ObservableObject {
    
    @Published private(set) var members: [GroupMember] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var didLeaveOrDelete = false
    
    @Published private(set) var group: DamaGroup
    
    init(group: DamaGroup) {
        self.group = group
    }
    
    /// 편집·재발급 후 Firestore에서 최신 group 재조회.
    private func refreshGroup() async {
        guard let groupId = group.id else { return }
        do {
            group = try await GroupService.shared.fetchGroup(groupId)
        } catch {
            // 조용히 실패 — 다음 진입 시 fresh fetch됨
        }
    }
    
    // MARK: - Load
    
    func loadMembers() async {
        guard let groupId = group.id else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            members = try await GroupService.shared.fetchMembers(groupId: groupId)
        } catch let error as GroupError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = GroupError.firestoreFailure(error).errorDescription
        }
    }
    
    // MARK: - Leave
    
    func leave(uid: String) async -> Bool {
        guard let groupId = group.id else { return false }
        do {
            try await GroupService.shared.leaveGroup(groupId: groupId, uid: uid)
            didLeaveOrDelete = true
            return true
        } catch let error as GroupError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = GroupError.firestoreFailure(error).errorDescription
            return false
        }
    }
    
    // MARK: - Delete
    
    func delete(uid: String) async -> Bool {
        guard let groupId = group.id else { return false }
        do {
            try await GroupService.shared.deleteGroup(groupId: groupId, ownerUid: uid)
            didLeaveOrDelete = true
            return true
        } catch let error as GroupError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = GroupError.firestoreFailure(error).errorDescription
            return false
        }
    }
    
    // MARK: - Update Info
    
    func updateInfo(name: String, coverEmoji: String?, ownerUid: String) async -> Bool {
        guard let groupId = group.id else { return false }
        do {
            try await GroupService.shared.updateGroupInfo(
                groupId: groupId,
                ownerUid: ownerUid,
                name: name,
                coverEmoji: coverEmoji
            )
            // 로컬 group은 immutable이라 직접 수정 불가 — 성공 후 재로드
            
            await refreshGroup()
            return true
        } catch let error as GroupError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = GroupError.firestoreFailure(error).errorDescription
            return false
        }
    }
    
    // MARK: - Regenerate Invite Code
    
    func regenerateInviteCode(ownerUid: String) async -> String? {
        guard let groupId = group.id else { return nil }
        do {
            let updated = try await GroupService.shared.regenerateInviteCode(
                groupId: groupId,
                ownerUid: ownerUid
            )
            group = updated
            return updated.inviteCode
        } catch let error as GroupError {
            errorMessage = error.errorDescription
            return nil
        } catch {
            errorMessage = GroupError.firestoreFailure(error).errorDescription
            return nil
        }
    }
    
    // MARK: - Transfer Ownership
    
    func transferOwnership(to newOwnerUid: String, currentOwnerUid: String) async -> Bool {
        guard let groupId = group.id else { return false }
        do {
            try await GroupService.shared.transferOwnership(
                groupId: groupId,
                currentOwnerUid: currentOwnerUid,
                newOwnerUid: newOwnerUid
            )
            await loadMembers()  // 역할 반영
            return true
        } catch let error as GroupError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = GroupError.firestoreFailure(error).errorDescription
            return false
        }
    }
    
    // MARK: - Remove Member
    
    func removeMember(targetUid: String, ownerUid: String) async -> Bool {
        guard let groupId = group.id else { return false }
        do {
            try await GroupService.shared.removeMember(
                groupId: groupId,
                ownerUid: ownerUid,
                targetUid: targetUid
            )
            members.removeAll { $0.userId == targetUid }
            return true
        } catch let error as GroupError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = GroupError.firestoreFailure(error).errorDescription
            return false
        }
    }
    
    // MARK: - Error
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Helpers
    
    func isOwner(uid: String) -> Bool {
        group.ownerId == uid
    }
}
