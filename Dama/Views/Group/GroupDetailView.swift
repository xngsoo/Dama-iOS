//
//  GroupDetailView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  dama — Group Detail (Photo Album)

import SwiftUI
import PhotosUI

struct GroupDetailView: View {
    
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var viewModel: GroupDetailViewModel
    @StateObject private var uploadViewModel = PhotoUploadViewModel()
    
    /// 홈 리스트 갱신을 위한 참조 (옵셔널 — 다른 진입 경로에서도 재사용 가능하도록).
    private let homeViewModel: HomeViewModel?
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var pickerSelection: [PhotosPickerItem] = []
    @State private var isPresentingUploadSheet = false
    
    init(group: DamaGroup, homeViewModel: HomeViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: GroupDetailViewModel(group: group))
        self.homeViewModel = homeViewModel
    }
    
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)
    private let uploadLimit = 10
    
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
                    // Phase 7에서 그룹 설정
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.damaInk)
                }
            }
        }
        .task {
            await viewModel.loadPhotos()
        }
        .onChange(of: pickerSelection) { newItems in
            guard !newItems.isEmpty else { return }
            Task { await handlePickerSelection(newItems) }
        }
        .sheet(isPresented: $isPresentingUploadSheet) {
            PhotoUploadSheet(viewModel: uploadViewModel) {
                isPresentingUploadSheet = false
                uploadViewModel.reset()
            }
            .presentationDetents([.medium])
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
                                // Phase 7: 사진 상세 뷰
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
            
            uploadPicker(label: {
                DamaButtonLabel(title: "사진 올리기")
            })
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
        uploadPicker(label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(_PrimaryCream)
                .frame(width: 52, height: 52)
                .background(Color.damaCoral)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
        })
        .padding(.trailing, DamaSpacing.lg)
        .padding(.bottom, DamaSpacing.lg)
    }
    
    // MARK: - Photos Picker Wrapper
    
    private func uploadPicker<Label: View>(
        @ViewBuilder label: @escaping () -> Label
    ) -> some View {
        PhotosPicker(
            selection: $pickerSelection,
            maxSelectionCount: uploadLimit,
            matching: .images
        ) {
            label()
        }
    }
    
    private let _PrimaryCream = Color(red: 251/255, green: 244/255, blue: 229/255)
    
    // MARK: - Handle Picker Selection
    
    private func handlePickerSelection(_ items: [PhotosPickerItem]) async {
        guard let user = auth.currentUser, let groupId = viewModel.group.id else {
            pickerSelection = []
            return
        }
        
        // 1. PhotosPickerItem → UIImage 변환
        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        
        pickerSelection = []  // 선택 상태 즉시 클리어
        
        guard !images.isEmpty else { return }
        
        // 2. 업로드 시트 띄우고 업로드 시작
        isPresentingUploadSheet = true
        
        let uploaded = await uploadViewModel.uploadImages(
            images,
            groupId: groupId,
            uploader: user
        )
        
        // 3. 그리드에 즉시 반영
        viewModel.prependUploaded(uploaded)
        
        // 홈 그리드에도 반영
        homeViewModel?.didUploadPhotos(groupId: groupId, count: uploaded.count)
    }
}

// MARK: - Helper View

/// PhotosPicker의 label로 쓸 DamaButton 스타일 라벨.
/// (PhotosPicker가 자체 Button을 만들기 때문에 DamaButton을 직접 쓰면 이중 Button이 됨)
private struct DamaButtonLabel: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.damaLabel)
            .foregroundColor(Color(red: 251/255, green: 244/255, blue: 229/255))
            .frame(maxWidth: .infinity)
            .padding(.vertical, DamaSpacing.md)
            .background(Color.damaCoral)
            .clipShape(Capsule())
    }
}
