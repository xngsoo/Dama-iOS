//
//  DamaCard.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//

import SwiftUI

/// Dama 디자인 시스템의 범용 카드 컨테이너 컴포넌트.
///
/// - Description:
///   앱 전반에서 재사용되는 카드 UI로, `action`을 전달하면 탭 가능한 카드로 동작한다.
///   내부 콘텐츠는 자유롭게 구성할 수 있으며, 일관된 패딩, 배경, 테두리 스타일을 제공한다.
///
/// - Behavior:
///   - action이 nil인 경우: 단순 정보 표시용 카드
///   - action이 있는 경우: Button으로 감싸져 탭 인터랙션 제공
///
/// - Parameters:
///   - action: 카드 탭 시 실행되는 클로저 (선택)
///   - content: 카드 내부에 표시할 View
///
/// - Example:
/// ```swift
/// DamaCard {
///     VStack { ... }
/// }
///
/// DamaCard(action: {
///     navigate()
/// }) {
///     HStack { ... }
/// }
/// ```
///
/// - Note:
///   카드 내부 여백, 배경색, radius는 디자인 시스템 기준을 따른다.
public struct DamaCard<Content: View>: View {
    
    private let action: (() -> Void)?
    private let content: Content
    
    init(
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.action = action
        self.content = content()
    }
    
    public var body: some View {
        Group {
            if let action = action {
                Button(action: action) { cardBody }
                    .buttonStyle(DamaCardPressStyle())
            } else {
                cardBody
            }
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

private struct DamaCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Light") {
    previewContent()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    previewContent()
        .preferredColorScheme(.dark)
}

private func previewContent() -> some View {
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
