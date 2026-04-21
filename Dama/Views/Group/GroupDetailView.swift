//
//  GroupDetailView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  dama — Group Detail (Photo Album)
//
//  그룹 상세: 상단 헤더 + 3열 사진 그리드.
//  업로드 버튼은 Phase 3c-②b에서 실제 연결.

import SwiftUI

struct GroupDetailView: View {
    
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var viewModel: GroupDetailViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    init(group: DamaGroup) {
        _viewModel = StateObject(wrappedValue: GroupDetailViewModel(group: group))
    }
    
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)
    
    var body: some View {
        ZStack {
            Color.damaCream.ignoresSafeArea()
            content
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(viewModel.group.name)
                    .font(.damaLabel)
                    .foregroundColor(.damaInk)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // Phase 7에서 그룹 설정 화면 연결
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.damaInk)
                }
            }
        }
        .task {
            await viewModel.loadPhotos()
        }
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.photos.isEmpty {
            ProgressView()
                .tint(.damaCoral)
        } else if viewModel.photos.isEmpty {
            emptyState
        } else {
            photoGrid
        }
    }
    
    // MARK: - Photo Grid
    
    private var photoGrid: some View {
        ScrollView {
            VStack(spacing: 0) {
                groupHeader
                    .padding(.horizontal, DamaSpacing.lg)
                    .padding(.vertical, DamaSpacing.md)
                
                LazyVGrid(columns: gridColumns, spacing: 4) {
                    ForEach(viewModel.photos) { photo in
                        PhotoThumbnailView(photo: photo)
                            .onTapGesture {
                                // Phase 7에서 사진 상세 뷰로
                            }
                    }
                }
                .padding(.horizontal, DamaSpacing.md)
                .padding(.bottom, DamaSpacing.xxl)
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .overlay(alignment: .bottomTrailing) {
            uploadFAB
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 0) {
            groupHeader
                .padding(.horizontal, DamaSpacing.lg)
                .padding(.vertical, DamaSpacing.md)
            
            Spacer()
            
            VStack(spacing: DamaSpacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.damaCreamWarm)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 30))
                        .foregroundColor(.damaInkSubtle)
                }
                
                VStack(spacing: DamaSpacing.xs) {
                    Text("아직 사진이 없어요")
                        .font(.damaSubheadline)
                        .foregroundColor(.damaInk)
                    
                    Text("첫 번째 추억을 담아보세요")
                        .font(.damaCaption)
                        .foregroundColor(.damaInkMuted)
                }
            }
            .padding(.bottom, DamaSpacing.xl)
            
            Spacer()
            
            DamaButton("사진 올리기", fullWidth: true) {
                handleUploadTap()
            }
            .padding(.horizontal, DamaSpacing.xl)
            .padding(.bottom, DamaSpacing.xl)
        }
    }
    
    // MARK: - Group Header
    
    private var groupHeader: some View {
        HStack(spacing: DamaSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: DamaRadius.md)
                    .fill(Color.damaColor(for: viewModel.group.id ?? viewModel.group.name))
                    .frame(width: 56, height: 56)
                
                if let emoji = viewModel.group.coverEmoji {
                    Text(emoji)
                        .font(.system(size: 28))
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.group.memberCount)명 함께")
                    .font(.damaCaption)
                    .foregroundColor(.damaInkMuted)
                
                Text("사진 \(viewModel.photos.count)장")
                    .font(.damaCaption)
                    .foregroundColor(.damaInkMuted)
                
                Text("초대 코드 · \(viewModel.group.inviteCode)")
                    .font(.damaMicro)
                    .foregroundColor(.damaInkSubtle)
            }
            
            Spacer()
        }
        .padding(DamaSpacing.md)
        .background(Color.damaCreamWarm)
        .clipShape(RoundedRectangle(cornerRadius: DamaRadius.md))
    }
    
    // MARK: - Upload FAB
    
    private var uploadFAB: some View {
        Button {
            handleUploadTap()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(_PrimaryCream)
                .frame(width: 52, height: 52)
                .background(Color.damaCoral)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
        }
        .padding(.trailing, DamaSpacing.lg)
        .padding(.bottom, DamaSpacing.lg)
    }
    
    private let _PrimaryCream = Color(red: 251/255, green: 244/255, blue: 229/255)
    
    // MARK: - Actions
    
    private func handleUploadTap() {
        // Phase 3c-②b에서 PhotoPicker 연결
        print("📸 업로드 탭 — Phase 3c-②b에서 구현 예정")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GroupDetailView(
            group: DamaGroup(
                id: "preview",
                name: "찐친클럽",
                coverEmoji: "🥂",
                inviteCode: "ABC123",
                ownerId: "me",
                memberIds: ["me", "a", "b"],
                memberCount: 3,
                photoCount: 0
            )
        )
        .environmentObject(AuthViewModel())
    }
}
