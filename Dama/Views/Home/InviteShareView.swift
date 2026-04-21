//
//  InviteShareView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  그룹 생성 성공 후 표시. 초대 코드를 크게 보여주고 공유/복사 액션 제공.

import SwiftUI

struct InviteShareView: View {
    
    let group: DamaGroup
    let onDone: () -> Void
    
    @State private var copied = false
    @State private var tileOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: DamaSpacing.xl) {
            Spacer()
            
            // MARK: Celebrate
            DamaPhotoTile(rotation: -3) {
                ZStack {
                    Color.damaColor(for: group.id ?? group.name)
                    if let emoji = group.coverEmoji {
                        Text(emoji).font(.system(size: 50))
                    }
                }
                .frame(width: 140, height: 160)
            }
            .opacity(tileOpacity)
            
            VStack(spacing: DamaSpacing.sm) {
                Text("만들어졌어요")
                    .font(.damaHeadline)
                    .foregroundColor(.damaInk)
                
                Text("『\(group.name)』에 친구를 초대해보세요")
                    .font(.damaBody)
                    .foregroundColor(.damaInkMuted)
                    .multilineTextAlignment(.center)
            }
            
            // MARK: Invite Code
            VStack(spacing: DamaSpacing.sm) {
                Text("초대 코드")
                    .font(.damaMicro)
                    .foregroundColor(.damaInkSubtle)
                    .tracking(1.5)
                
                Text(group.inviteCode)
                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                    .foregroundColor(.damaInk)
                    .tracking(4)
            }
            .padding(.vertical, DamaSpacing.lg)
            .padding(.horizontal, DamaSpacing.xl)
            .background(Color.damaCreamWarm)
            .clipShape(RoundedRectangle(cornerRadius: DamaRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: DamaRadius.lg)
                    .stroke(Color.damaBorder, lineWidth: 0.5)
            )
            
            Spacer()
            
            // MARK: Actions
            VStack(spacing: DamaSpacing.sm) {
                
                ShareLink(item: shareMessage) {
                    HStack(spacing: DamaSpacing.sm) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .medium))
                        Text("초대 링크 공유")
                            .font(.damaLabel)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, DamaSpacing.lg)
                    .padding(.vertical, DamaSpacing.md)
                    .foregroundColor(_PrimaryCream)
                    .background(Color.damaCoral)
                    .clipShape(Capsule())
                }
                
                DamaButton(copied ? "복사됨" : "코드 복사", variant: .secondary, fullWidth: true) {
                    copyCode()
                }
                .animation(.easeInOut, value: copied)
                
                DamaButton("나중에", variant: .text, action: onDone)
            }
            .padding(.horizontal, DamaSpacing.xl)
            .padding(.bottom, DamaSpacing.xl)
        }
        .task {
            withAnimation(.easeOut(duration: 0.5)) { tileOpacity = 1 }
        }
    }
    
    // MARK: - Helpers
    
    private let _PrimaryCream = Color(red: 251/255, green: 244/255, blue: 229/255)
    
    private var shareMessage: String {
        """
        📷 담아에서 『\(group.name)』 앨범에 초대할게!
        
        아래 코드를 앱에서 입력하면 돼.
        
        \(group.inviteCode)
        """
    }
    
    private func copyCode() {
        UIPasteboard.general.string = group.inviteCode
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            copied = false
        }
    }
}

#Preview {
    InviteShareView(
        group: DamaGroup(
            id: "p1",
            name: "찐친클럽",
            coverEmoji: "🥂",
            inviteCode: "ABC123",
            ownerId: "me",
            memberIds: ["me"],
            memberCount: 1,
            photoCount: 0
        ),
        onDone: { }
    )
    .background(Color.damaCream.ignoresSafeArea())
}
