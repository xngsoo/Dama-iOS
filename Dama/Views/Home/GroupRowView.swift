//
//  GroupRowView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  홈 화면 그룹 리스트의 한 줄. DamaCard 기반.

import SwiftUI
import FirebaseCore

struct GroupRowView: View {
    
    let group: DamaGroup
    let onTap: (() -> Void)?
    
    init(group: DamaGroup, onTap: (() -> Void)? = nil) {
        self.group = group
        self.onTap = onTap
    }
    
    var body: some View {
        DamaCard(action: onTap) {
            HStack(spacing: DamaSpacing.md) {
                
                // MARK: Cover
                ZStack {
                    RoundedRectangle(cornerRadius: DamaRadius.sm)
                        .fill(Color.damaColor(for: group.id ?? group.name))
                        .frame(width: 44, height: 44)
                    
                    if let emoji = group.coverEmoji {
                        Text(emoji)
                            .font(.system(size: 22))
                    }
                }
                
                // MARK: Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(group.name)
                        .font(.damaLabel)
                        .foregroundColor(.damaInk)
                        .lineLimit(1)
                    
                    Text("\(group.memberCount)명 · 사진 \(group.photoCount)장")
                        .font(.damaCaption)
                        .foregroundColor(.damaInkMuted)
                    
                    if let lastPhotoAt = group.lastPhotoAt {
                        Text(lastPhotoAt.relativeKoreanString)
                            .font(.damaMicro)
                            .foregroundColor(.damaInkSubtle)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.damaInkSubtle)
            }
        }
    }
}

// MARK: - Preview

#Preview("Light") {
    VStack(spacing: DamaSpacing.md) {
        GroupRowView(
            group: DamaGroup(
                id: "p1",
                name: "찐친클럽",
                coverEmoji: "🥂",
                inviteCode: "ABC123",
                ownerId: "me",
                memberIds: ["me", "a", "b"],
                memberCount: 3,
                photoCount: 127,
                lastPhotoAt: Timestamp(date: Date().addingTimeInterval(-7200))
            ),
            onTap: { }
        )
        GroupRowView(
            group: DamaGroup(
                id: "p2",
                name: "우리 가족",
                coverEmoji: "🏡",
                inviteCode: "FAM456",
                ownerId: "me",
                memberIds: ["me"],
                memberCount: 5,
                photoCount: 482,
                lastPhotoAt: Timestamp(date: Date())
            ),
            onTap: { }
        )
    }
    .padding(DamaSpacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.damaCream)
}

#Preview("Dark") {
    GroupRowView(
        group: DamaGroup(
            id: "p3",
            name: "제주 2025",
            coverEmoji: "🌊",
            inviteCode: "JEJ789",
            ownerId: "me",
            memberIds: ["me"],
            memberCount: 4,
            photoCount: 89,
            lastPhotoAt: Timestamp(date: Date().addingTimeInterval(-86400 * 7))
        ),
        onTap: { }
    )
    .padding(DamaSpacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.damaCream)
    .preferredColorScheme(.dark)
}
