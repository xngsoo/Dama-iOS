//
//  PhotoThumbnailView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  dama — Photo Grid Cell
//
//  Storage 경로로부터 download URL을 비동기 획득 → AsyncImage로 로드.

import SwiftUI

struct PhotoThumbnailView: View {
    
    let photo: Photo
    
    @State private var url: URL?
    @State private var loadError = false
    
    var body: some View {
        ZStack {
            Color.damaCreamWarm
            
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .controlSize(.small)
                            .tint(.damaInkSubtle)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder(systemImage: "photo.fill")
                    @unknown default:
                        placeholder(systemImage: "questionmark")
                    }
                }
            } else if loadError {
                placeholder(systemImage: "exclamationmark.triangle")
            } else {
                ProgressView()
                    .controlSize(.small)
                    .tint(.damaInkSubtle)
            }
        }
        .task(id: photo.id) {
            await loadURL()
        }
    }
    
    private func loadURL() async {
        // 썸네일 우선, 없으면 원본 fallback
        let path = photo.thumbnailPath ?? photo.storagePath
        do {
            url = try await PhotoService.shared.downloadURL(storagePath: path)
            loadError = false
        } catch {
            loadError = true
        }
    }
    
    private func placeholder(systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 18))
            .foregroundColor(.damaInkSubtle)
    }
}
