//
//  HomeViewModel.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  현재는 더미 데이터로 동작.
//  Phase 3c에서 GroupService로 교체 예정.

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
    }
    
    // MARK: - Load
    
    func loadGroups() async {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Phase 3c — GroupService.shared.fetchGroups(for: uid)
        try? await Task.sleep(for: .milliseconds(400))
        if groups.isEmpty {
            groups = Self.makeDummyGroups()
        }
    }
    
    func refresh() async {
        await loadGroups()
    }
    
    // MARK: - Create
    
    /// 새 그룹을 생성하고 리스트 최상단에 추가.
    /// 현재는 메모리 더미. Phase 3c에서 GroupService.shared.createGroup 로 교체.
    @discardableResult
    func createGroup(
        name: String,
        coverEmoji: String?,
        ownerId: String
    ) async -> DamaGroup {
        // TODO: Phase 3c — 실제 Firestore 생성
        try? await Task.sleep(for: .milliseconds(400))
        
        let now = Timestamp(date: Date())
        var new = DamaGroup.new(name: name, ownerId: ownerId, coverEmoji: coverEmoji)
        new.id = "local-\(UUID().uuidString.prefix(8))"
        new.createdAt = now
        new.updatedAt = now
        
        groups.insert(new, at: 0)
        return new
    }
    
    // MARK: - Join
    
    /// 초대 코드로 기존 그룹에 참여. 현재는 로컬 배열에서 코드 매칭.
    /// Phase 3c에서 Firestore collectionGroup 쿼리로 교체.
    func joinGroup(inviteCode: String) async -> JoinResult {
        try? await Task.sleep(for: .milliseconds(500))
        
        // TODO: Phase 3c — GroupService.shared.joinByInviteCode(code, uid)
        guard let index = groups.firstIndex(where: { $0.inviteCode == inviteCode }) else {
            return .notFound
        }
        let group = groups[index]
        
        if group.isFull { return .full }
        // 더미 단계에선 이미 참여 중 판별이 불완전하므로 간단히 처리
        return .alreadyMember
    }
    
    // MARK: - Dummy Data
    
    private static func makeDummyGroups() -> [DamaGroup] {
        let now = Timestamp(date: Date())
        let hoursAgo: (Int) -> Timestamp = { hours in
            Timestamp(date: Date().addingTimeInterval(-Double(hours * 3600)))
        }
        
        return [
//            DamaGroup(
//                id: "dummy-1",
//                name: "찐친클럽",
//                coverEmoji: "🥂",
//                inviteCode: "ABC123",
//                ownerId: "me",
//                memberIds: ["me", "a", "b"],
//                memberCount: 3,
//                photoCount: 127,
//                createdAt: hoursAgo(24 * 40),
//                updatedAt: hoursAgo(48),
//                lastPhotoAt: hoursAgo(48)
//            ),
//            DamaGroup(
//                id: "dummy-2",
//                name: "우리 가족",
//                coverEmoji: "🏡",
//                inviteCode: "FAM456",
//                ownerId: "me",
//                memberIds: ["me", "c", "d", "e", "f"],
//                memberCount: 5,
//                photoCount: 482,
//                createdAt: hoursAgo(24 * 180),
//                updatedAt: now,
//                lastPhotoAt: now
//            ),
//            DamaGroup(
//                id: "dummy-3",
//                name: "제주 2025",
//                coverEmoji: "🌊",
//                inviteCode: "JEJ789",
//                ownerId: "me",
//                memberIds: ["me", "g", "h", "i"],
//                memberCount: 4,
//                photoCount: 89,
//                createdAt: hoursAgo(24 * 7),
//                updatedAt: hoursAgo(24 * 7),
//                lastPhotoAt: hoursAgo(24 * 7)
//            ),
        ]
    }
}
