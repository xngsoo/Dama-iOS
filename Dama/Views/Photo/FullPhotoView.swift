//
//  FullPhotoView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  원본 사진을 Storage에서 로드해 AsyncImage로 렌더.
//  pinch-to-zoom + double-tap zoom 지원.

import SwiftUI

struct FullPhotoView: View {
    
    let photo: Photo
    
    @State private var url: URL?
    @State private var loadFailed = false
    
    // Zoom state
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.damaInk  // 제스처 인식용
                
                Group {
                    if let url {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .tint(.damaInkSubtle)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .scaleEffect(scale)
                                    .gesture(magnificationGesture)
                                    .onTapGesture(count: 2) {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            scale = scale > 1.0 ? 1.0 : 2.5
                                            lastScale = scale
                                        }
                                    }
                            case .failure:
                                failurePlaceholder
                            @unknown default:
                                failurePlaceholder
                            }
                        }
                    } else if loadFailed {
                        failurePlaceholder
                    } else {
                        ProgressView()
                            .tint(.damaInkSubtle)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .task(id: photo.id) {
                await loadURL()
            }
        }
    }
    
    // MARK: - Gestures
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = lastScale * value
                scale = min(max(newScale, 1.0), 4.0)
            }
            .onEnded { _ in
                if scale < 1.0 {
                    withAnimation(.easeOut(duration: 0.2)) { scale = 1.0 }
                }
                lastScale = scale
            }
    }
    
    // MARK: - Helpers
    
    private func loadURL() async {
        do {
            url = try await PhotoService.shared.downloadURL(storagePath: photo.storagePath)
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }
    
    private var failurePlaceholder: some View {
        VStack(spacing: DamaSpacing.sm) {
            Image(systemName: "photo")
                .font(.system(size: 44))
                .foregroundColor(.damaInkSubtle)
            Text("사진을 불러오지 못했어요")
                .font(.damaCaption)
                .foregroundColor(.damaInkMuted)
        }
    }
}
