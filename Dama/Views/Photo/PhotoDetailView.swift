//
//  PhotoDetailView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  여러 장의 사진을 풀스크린으로 스와이프하며 보고 좋아요 토글.
//  댓글은 Phase 7a-②에서 바텀 시트로 추가.

import SwiftUI
import FirebaseCore

struct PhotoDetailView: View {
    
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    let photos: [Photo]
    @State private var currentIndex: Int
    
    /// 인덱스별 ViewModel (좋아요 상태 등을 유지).
    @State private var viewModels: [String: PhotoDetailViewModel]
    @State private var isPresentingComments = false
    
    init(photos: [Photo], startIndex: Int) {
        self.photos = photos
        self._currentIndex = State(initialValue: startIndex)
        
        // 모든 사진에 대해 VM 미리 생성 — dictionary 접근 비용 최소화
        var initial: [String: PhotoDetailViewModel] = [:]
        for photo in photos {
            if let id = photo.id {
                initial[id] = PhotoDetailViewModel(photo: photo)
            }
        }
        self._viewModels = State(initialValue: initial)
    }
    
    var body: some View {
        ZStack {
            Color.damaInk.ignoresSafeArea()
            
            TabView(selection: $currentIndex) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    FullPhotoView(photo: photo)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            VStack {
                topBar
                Spacer()
                if let vm = currentViewModel {
                    BottomBar(
                        viewModel: vm,
                        uid: auth.currentUser?.id ?? "",
                        onCommentTap: { isPresentingComments = true }
                    )
                }
            }
        }
        .statusBar(hidden: true)
        .navigationBarHidden(true)
        .sheet(isPresented: $isPresentingComments) {
            if let vm = currentViewModel {
                CommentsSheet(photo: vm.photo) { delta in
                    vm.didChangeCommentCount(delta: delta)
                }
                .environmentObject(auth)
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(_TopBarTint)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("\(currentIndex + 1) / \(photos.count)")
                .font(.damaCaption)
                .foregroundColor(_TopBarTint)
                .padding(.horizontal, DamaSpacing.md)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.35))
                .clipShape(Capsule())
            
            Spacer()
            
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, DamaSpacing.lg)
        .padding(.top, DamaSpacing.xl + DamaSpacing.sm)
    }
    
    // MARK: - Helpers
    
    private var currentViewModel: PhotoDetailViewModel? {
        guard currentIndex >= 0, currentIndex < photos.count else { return nil }
        guard let id = photos[currentIndex].id else { return nil }
        return viewModels[id]
    }
    
    private let _TopBarTint = Color(red: 251/255, green: 244/255, blue: 229/255)
}

// MARK: - Bottom Bar (별도 View로 분리해 ObservableObject 관찰을 명확히)

private struct BottomBar: View {
    
    @ObservedObject var viewModel: PhotoDetailViewModel
    let uid: String
    let onCommentTap: () -> Void
    
    private let tint = Color(red: 251/255, green: 244/255, blue: 229/255)
    
    var body: some View {
        let isLiked = viewModel.photo.isLikedBy(uid)
        
        return VStack(alignment: .leading, spacing: DamaSpacing.sm) {
            HStack(spacing: DamaSpacing.md) {
                // 좋아요
                Button {
                    Task { await viewModel.toggleLike(uid: uid) }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundColor(isLiked ? .damaCoral : tint)
                        Text("\(viewModel.photo.likeCount)")
                            .font(.damaCaption)
                            .foregroundColor(tint)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, DamaSpacing.md)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Capsule())
                }
                .animation(.spring(response: 0.3), value: isLiked)
                
                // 댓글 (Phase 7a-② stub)
                Button {
                    onCommentTap()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 18))
                            .foregroundColor(tint)
                        Text("\(viewModel.photo.commentCount)")
                            .font(.damaCaption)
                            .foregroundColor(tint)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, DamaSpacing.md)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                // 메뉴 (Phase 7a-③ stub)
                Button {
                    // TODO
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(tint)
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.35))
                        .clipShape(Circle())
                }
            }
            
            // 메타
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(viewModel.photo.uploaderName)
                        .font(.damaCaption)
                        .foregroundColor(tint)
                    Text("·")
                        .foregroundColor(tint.opacity(0.6))
                    if let uploadedAt = viewModel.photo.uploadedAt {
                        Text(uploadedAt.relativeKoreanString)
                            .font(.damaMicro)
                            .foregroundColor(tint.opacity(0.7))
                    }
                }
                
                if let caption = viewModel.photo.caption, !caption.isEmpty {
                    Text(caption)
                        .font(.damaCaption)
                        .foregroundColor(tint)
                        .lineLimit(3)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, DamaSpacing.lg)
        .padding(.bottom, DamaSpacing.xl)
    }
}
