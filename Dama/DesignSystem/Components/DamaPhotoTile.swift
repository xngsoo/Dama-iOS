//
//  DamaPhotoTile.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//

import SwiftUI

/// Dama 디자인 시스템의 사진 타일(Polaroid 스타일) 컴포넌트
///
/// - Description:
///   사진과 캡션을 함께 표시하는 카드 형태의 UI로, 약간의 회전(`rotation`)을 통해
///   감성적인 폴라로이드 스타일을 표현한다. `action`을 전달하면 탭 가능한 인터랙션을 제공한다.
///
/// - Behavior:
///   - caption이 nil인 경우: 캡션 영역 없이 사진만 표시
///   - action이 있는 경우: Button으로 감싸져 탭 인터랙션 제공
///   - rotation 값에 따라 전체 타일이 회전됨
///
/// - Parameters:
///   - caption: 사진 하단에 표시될 텍스트 (옵션)
///   - rotation: 타일 회전 각도 (degree 단위)
///   - action: 타일 탭 시 실행되는 클로저 (옵션)
///   - photo: 사진 영역에 들어갈 View
///
/// - Example:
/// ```swift
/// DamaPhotoTile(caption: "그날 밤", rotation: -2) {
///     Image("sample")
///         .resizable()
///         .aspectRatio(contentMode: .fill)
/// }
///
/// DamaPhotoTile {
///     Color.gray
/// }
/// ```
///
/// - Note:
///   폰트, 여백, 배경색은 Dama 디자인 시스템 토큰을 따른다.
struct DamaPhotoTile<Content: View>: View {
    
    private let caption: String?
    private let rotation: Double
    private let action: (() -> Void)?
    private let content: Content
    
    init(
        caption: String? = nil,
        rotation: Double = 0,
        action: (() -> Void)? = nil,
        @ViewBuilder photo: () -> Content
    ) {
        self.caption = caption
        self.rotation = rotation
        self.action = action
        self.content = photo()
    }
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: action) { tile }
                    .buttonStyle(_DamaPhotoTilePressStyle())
            } else {
                tile
            }
        }
        .rotationEffect(.degrees(rotation))
    }
    
    private var tile: some View {
        VStack(spacing: DamaSpacing.xs) {
            content
                .clipShape(RoundedRectangle(cornerRadius: 2))
            
            if let caption = caption {
                Text(caption)
                    .font(.custom("NanumMyeongjo", size: 10))
                    .foregroundColor(.damaInk)
                    .lineLimit(1)
                    .padding(.horizontal, DamaSpacing.xs)
                    .padding(.bottom, DamaSpacing.xs)
            }
        }
        .padding(DamaSpacing.xs)
        .padding(.bottom, caption == nil ? DamaSpacing.sm : 0)
        .background(Color.damaCreamWarm)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

private struct _DamaPhotoTilePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
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
    ScrollView {
        VStack(spacing: DamaSpacing.xl) {
            
            DamaPhotoTile(caption: "그날 밤, 종로", rotation: -1.5) {
                Color.damaCoral
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 200)
            }
            
            DamaPhotoTile(rotation: 1) {
                Color.damaCaramel
                    .aspectRatio(4/3, contentMode: .fit)
                    .frame(width: 220)
            }
            
            DamaPhotoTile(caption: "2025.11.13 · 승수", rotation: 2) {
                Color.damaSage
                    .aspectRatio(3/4, contentMode: .fit)
                    .frame(width: 180)
            }
        }
        .padding(DamaSpacing.xl)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.damaCream)
}
