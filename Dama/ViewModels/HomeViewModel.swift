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
    
    // MARK: - Load
    
    func loadGroups() async {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Phase 3c — GroupService.shared.fetchGroups(for: uid) 로 교체
        try? await Task.sleep(for: .milliseconds(400))
        groups = Self.makeDummyGroups()
    }
    
    func refresh() async {
        await loadGroups()
    }
    
    // MARK: - Dummy Data (Phase 3c에서 제거)
    
    private static func makeDummyGroups() -> [DamaGroup] {
        let now = Timestamp(date: Date())
        let hoursAgo: (Int) -> Timestamp = { hours in
            Timestamp(date: Date().addingTimeInterval(-Double(hours * 3600)))
        }
        
        return [
            DamaGroup(
                id: "dummy-1",
                name: "찐친클럽",
                coverEmoji: "🥂",
                inviteCode: "ABC123",
                ownerId: "me",
                memberIds: ["me", "a", "b"],
                memberCount: 3,
                photoCount: 127,
                createdAt: hoursAgo(24 * 40),
                updatedAt: hoursAgo(48),
                lastPhotoAt: hoursAgo(48)
            ),
            DamaGroup(
                id: "dummy-2",
                name: "우리 가족",
                coverEmoji: "🏡",
                inviteCode: "FAM456",
                ownerId: "me",
                memberIds: ["me", "c", "d", "e", "f"],
                memberCount: 5,
                photoCount: 482,
                createdAt: hoursAgo(24 * 180),
                updatedAt: now,
                lastPhotoAt: now
            ),
            DamaGroup(
                id: "dummy-3",
                name: "제주 2025",
                coverEmoji: "🌊",
                inviteCode: "JEJ789",
                ownerId: "me",
                memberIds: ["me", "g", "h", "i"],
                memberCount: 4,
                photoCount: 89,
                createdAt: hoursAgo(24 * 7),
                updatedAt: hoursAgo(24 * 7),
                lastPhotoAt: hoursAgo(24 * 7)
            ),
        ]
    }
}
