//
//  EmptyStateView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  그룹이 하나도 없을 때. "지금 시작하기"를 부드럽게 유도.

import SwiftUI

struct EmptyStateView: View {
    
    let onCreateGroup: () -> Void
    let onJoinGroup: () -> Void
    
    @State private var tileOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: DamaSpacing.xl) {
            Spacer()
            
            // 겹친 폴라로이드 3장 — 담아 시그니처
            ZStack {
                DamaPhotoTile(rotation: -8) {
                    Color.damaSage.frame(width: 90, height: 90)
                }
                .offset(x: -50, y: 14)
                
                DamaPhotoTile(rotation: 3) {
                    Color.damaCaramel.frame(width: 90, height: 90)
                }
                
                DamaPhotoTile(rotation: -2) {
                    Color.damaCoral.frame(width: 90, height: 90)
                }
                .offset(x: 50, y: -10)
            }
            .opacity(tileOpacity)
            .padding(.bottom, DamaSpacing.md)
            
            VStack(spacing: DamaSpacing.sm) {
                Text("우리만의 공간을\n만들어볼까요")
                    .font(.damaHeadline)
                    .foregroundColor(.damaInk)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Text("소중한 사람들과 추억을 나눌\n작은 앨범이 기다리고 있어요")
                    .font(.damaBody)
                    .foregroundColor(.damaInkMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.horizontal, DamaSpacing.xl)
            
            Spacer()
            
            VStack(spacing: DamaSpacing.sm) {
                DamaButton("새 그룹 만들기", fullWidth: true, action: onCreateGroup)
                DamaButton("초대 코드로 참여", variant: .secondary, fullWidth: true, action: onJoinGroup)
            }
            .padding(.horizontal, DamaSpacing.xl)
            .padding(.bottom, DamaSpacing.xl)
        }
        .task {
            withAnimation(.easeOut(duration: 0.6)) {
                tileOpacity = 1
            }
        }
    }
}

#Preview("Light") {
    EmptyStateView(onCreateGroup: { }, onJoinGroup: { })
        .background(Color.damaCream)
}

#Preview("Dark") {
    EmptyStateView(onCreateGroup: { }, onJoinGroup: { })
        .background(Color.damaCream)
        .preferredColorScheme(.dark)
}
