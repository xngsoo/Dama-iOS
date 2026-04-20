//
//  DamaCard.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//
//  범용 카드 컨테이너. action 전달 시 탭 가능.
//    사용 예:
//    DamaCard { VStack { ... } }
//    DamaCard(action: { navigate() }) { HStack { ... } }

import SwiftUI

struct DamaCard<Content: View>: View {
    
    private let action: (() -> Void)?
    private let content: Content
    
    init(
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        if let action = action {
            Button(action: action) { cardBody }
                .buttonStyle(_DamaCardPressStyle())
        } else {
            cardBody
        }
    }
    
    private var cardBody: some View {
        content
            .padding(DamaSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.damaCreamWarm)
            .clipShape(RoundedRectangle(cornerRadius: DamaRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DamaRadius.md)
                    .stroke(Color.damaBorder, lineWidth: 0.5)
            )
    }
}

private struct _DamaCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Light") {
    VStack(spacing: DamaSpacing.md) {
        
        // 정보 카드 (탭 불가)
        DamaCard {
            VStack(alignment: .leading, spacing: DamaSpacing.xs) {
                Text("찐친클럽")
                    .font(.damaLabel)
                    .foregroundColor(.damaInk)
                Text("3명 · 사진 127장")
                    .font(.damaCaption)
                    .foregroundColor(.damaInkMuted)
                Text("2일 전")
                    .font(.damaMicro)
                    .foregroundColor(.damaInkSubtle)
            }
        }
        
        // 탭 가능한 카드
        DamaCard(action: { print("tapped") }) {
            HStack(spacing: DamaSpacing.md) {
                RoundedRectangle(cornerRadius: DamaRadius.sm)
                    .fill(Color.damaCoral)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: DamaSpacing.xs) {
                    Text("우리 가족")
                        .font(.damaLabel)
                        .foregroundColor(.damaInk)
                    Text("5명 · 482장 · 방금")
                        .font(.damaCaption)
                        .foregroundColor(.damaInkMuted)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.damaInkSubtle)
            }
        }
    }
    .padding(DamaSpacing.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.damaCream)
}

#Preview("Dark") {
    VStack(spacing: DamaSpacing.md) {
        DamaCard(action: { }) {
            VStack(alignment: .leading, spacing: DamaSpacing.xs) {
                Text("제주 2025")
                    .font(.damaLabel)
                    .foregroundColor(.damaInk)
                Text("4명 · 사진 89장")
                    .font(.damaCaption)
                    .foregroundColor(.damaInkMuted)
            }
        }
    }
    .padding(DamaSpacing.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.damaCream)
    .preferredColorScheme(.dark)
}
