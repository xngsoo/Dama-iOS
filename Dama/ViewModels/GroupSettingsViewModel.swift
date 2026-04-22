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
    
    let group: DamaGroup
    
    init(group: DamaGroup) {
        self.group = group
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
    
    // MARK: - Error
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Helpers
    
    func isOwner(uid: String) -> Bool {
        group.ownerId == uid
    }
}
