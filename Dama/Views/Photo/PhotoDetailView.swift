//
//  PhotoDetailView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  dama — Photo Detail Screen

import SwiftUI

struct PhotoDetailView: View {
    
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    let photos: [Photo]
    /// 그룹 owner id — 삭제 권한 체크용
    let groupOwnerId: String
    /// 삭제 발생 시 부모(그룹 상세)에 알림
    let onPhotoDeleted: (String) -> Void
    
    @State private var currentIndex: Int
    @State private var viewModels: [String: PhotoDetailViewModel]
    @State private var isPresentingComments = false
    @State private var showDeleteConfirm = false
    
    init(
        photos: [Photo],
        startIndex: Int,
        groupOwnerId: String,
        onPhotoDeleted: @escaping (String) -> Void = { _ in }
    ) {
        self.photos = photos
        self._currentIndex = State(initialValue: startIndex)
        self.groupOwnerId = groupOwnerId
        self.onPhotoDeleted = onPhotoDeleted
        
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
                        canDelete: canDeleteCurrent,
                        onCommentsTap: { isPresentingComments = true },
                        onDeleteTap: { showDeleteConfirm = true }
                    )
                }
            }
        }
        .statusBar(hidden: true)
        .navigationBarHidden(true)
        .onAppear {
            currentViewModel?.startListening()
        }
        .onDisappear {
            for (_, vm) in viewModels {
                vm.stopListening()
            }
        }
        .onChange(of: currentIndex) { _ in
            startListeningCurrent()
        }
        .sheet(isPresented: $isPresentingComments) {
            if let vm = currentViewModel {
                CommentsSheet(photo: vm.photo) { delta in
                    vm.didChangeCommentCount(delta: delta)
                }
                .environmentObject(auth)
            }
        }
        .confirmationDialog(
            "이 사진을 삭제할까요?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("삭제", role: .destructive) {
                Task { await performDelete() }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("한번 삭제하면 되돌릴 수 없어요")
        }
        .alert("앗", isPresented: errorBinding) {
            Button("확인", role: .cancel) {
                currentViewModel?.clearError()
            }
        } message: {
            Text(currentViewModel?.errorMessage ?? "")
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
    
    /// 현재 사진을 삭제할 수 있는지 — 본인 업로드 또는 그룹 owner
    private var canDeleteCurrent: Bool {
        guard let uid = auth.currentUser?.id else { return false }
        let isUploader = currentViewModel?.photo.uploaderId == uid
        let isOwner = groupOwnerId == uid
        return isUploader || isOwner
    }
    
    private func startListeningCurrent() {
        // 다른 페이지의 listener는 유지 — 스와이프로 빠르게 돌아왔을 때 재구독 비용 절약
        currentViewModel?.startListening()
    }
    
    private func performDelete() async {
        guard let vm = currentViewModel,
              let photoId = vm.photo.id else { return }
        
        if await vm.deletePhoto() {
            onPhotoDeleted(photoId)
            dismiss()
        }
    }
    
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { currentViewModel?.errorMessage != nil },
            set: { if !$0 { currentViewModel?.clearError() } }
        )
    }
    
    private let _TopBarTint = Color(red: 251/255, green: 244/255, blue: 229/255)
}

// MARK: - Bottom Bar

private struct BottomBar: View {
    
    @ObservedObject var viewModel: PhotoDetailViewModel
    let uid: String
    let canDelete: Bool
    let onCommentsTap: () -> Void
    let onDeleteTap: () -> Void
    
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
                
                // 댓글
                Button(action: onCommentsTap) {
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
                
                // 메뉴
                Menu {
                    if canDelete {
                        Button(role: .destructive, action: onDeleteTap) {
                            Label("사진 삭제", systemImage: "trash")
                        }
                    }
                    // 향후 확장: 신고, 다운로드, 공유 등
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(tint)
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.35))
                        .clipShape(Circle())
                }
                .disabled(!canDelete)  // 현재는 삭제만 있어서 권한 없으면 메뉴 비활성
                .opacity(canDelete ? 1 : 0.5)
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
