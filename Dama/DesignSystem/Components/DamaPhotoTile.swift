//
//  DamaPhotoTile.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//
//  담아 시그니처 폴라로이드 프레임. 회전·캡션·탭 지원.
//  사용 예:
//    DamaPhotoTile(caption: "그날 밤, 종로", rotation: -1.5) {
//        Color.damaCoral.aspectRatio(1, contentMode: .fit)
//    }

import SwiftUI

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

#Preview("Dark") {
    VStack {
        DamaPhotoTile(caption: "종로 밤거리", rotation: -2) {
            Color.damaTerracotta
                .aspectRatio(1, contentMode: .fit)
                .frame(width: 200)
        }
    }
    .padding(DamaSpacing.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.damaCream)
    .preferredColorScheme(.dark)
}
