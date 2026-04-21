//
//  CommentsSheet.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  dama — Comments Bottom Sheet

import SwiftUI

struct CommentsSheet: View {
    
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var viewModel: CommentsViewModel
    @Environment(\.dismiss) private var dismiss
    
    /// 부모 뷰(PhotoDetailView)의 로컬 photo.commentCount 동기화용 콜백.
    /// 댓글 추가 시 +1, 삭제 시 -1.
    let onCountChange: (Int) -> Void
    
    @State private var draft = ""
    @FocusState private var inputFocused: Bool
    
    init(photo: Photo, onCountChange: @escaping (Int) -> Void = { _ in }) {
        _viewModel = StateObject(wrappedValue: CommentsViewModel(photo: photo))
        self.onCountChange = onCountChange
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.damaCream.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    listArea
                    Divider()
                        .background(Color.damaDivider)
                    inputArea
                }
            }
            .navigationTitle("댓글")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                        .foregroundColor(.damaInkMuted)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            viewModel.startListening()
        }
        .onDisappear {
            viewModel.stopListening()
        }
        .alert("앗", isPresented: errorBinding) {
            Button("확인", role: .cancel) { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - List
    
    @ViewBuilder
    private var listArea: some View {
        if viewModel.comments.isEmpty {
            emptyView
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: DamaSpacing.md) {
                        ForEach(viewModel.comments) { comment in
                            CommentRow(
                                comment: comment,
                                isMine: comment.userId == (auth.currentUser?.id ?? ""),
                                onDelete: {
                                    Task {
                                        if await viewModel.delete(comment) {
                                            onCountChange(-1)
                                        }
                                    }
                                }
                            )
                            .id(comment.id)
                        }
                    }
                    .padding(.horizontal, DamaSpacing.lg)
                    .padding(.vertical, DamaSpacing.md)
                }
                .onChange(of: viewModel.comments.count) { _ in
                    if let last = viewModel.comments.last?.id {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: DamaSpacing.sm) {
            Spacer()
            Image(systemName: "bubble.left")
                .font(.system(size: 36))
                .foregroundColor(.damaInkSubtle)
            Text("아직 댓글이 없어요")
                .font(.damaSubheadline)
                .foregroundColor(.damaInk)
            Text("첫 번째 마음을 남겨주세요")
                .font(.damaCaption)
                .foregroundColor(.damaInkMuted)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Input
    
    private var inputArea: some View {
        HStack(alignment: .bottom, spacing: DamaSpacing.sm) {
            TextField("댓글을 남겨보세요", text: $draft, axis: .vertical)
                .font(.damaBody)
                .foregroundColor(.damaInk)
                .focused($inputFocused)
                .lineLimit(1...4)
                .padding(.horizontal, DamaSpacing.md)
                .padding(.vertical, 10)
                .background(Color.damaCreamWarm)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(inputFocused ? Color.damaCoral : Color.damaBorder,
                                lineWidth: inputFocused ? 1 : 0.5)
                )
                .animation(.easeInOut(duration: 0.15), value: inputFocused)
            
            Button {
                Task { await submit() }
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(_PrimaryCream)
                    .frame(width: 36, height: 36)
                    .background(canSubmit ? Color.damaCoral : Color.damaInkSubtle.opacity(0.5))
                    .clipShape(Circle())
            }
            .disabled(!canSubmit || viewModel.isSubmitting)
            .animation(.easeInOut(duration: 0.15), value: canSubmit)
        }
        .padding(.horizontal, DamaSpacing.lg)
        .padding(.vertical, DamaSpacing.md)
        .background(Color.damaCream)
    }
    
    // MARK: - Helpers
    
    private var canSubmit: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )
    }
    
    private func submit() async {
        guard let user = auth.currentUser else { return }
        let text = draft
        draft = ""
        
        if await viewModel.submit(text: text, author: user) {
            onCountChange(1)
        }
    }
    
    private let _PrimaryCream = Color(red: 251/255, green: 244/255, blue: 229/255)
}

// MARK: - Comment Row

private struct CommentRow: View {
    
    let comment: Comment
    let isMine: Bool
    let onDelete: () -> Void
    
    @State private var showDeleteConfirm = false
    
    var body: some View {
        HStack(alignment: .top, spacing: DamaSpacing.sm) {
            
            // Avatar
            Circle()
                .fill(Color.damaColor(for: comment.userId))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(avatarInitial)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(_PrimaryCream)
                )
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(comment.userName)
                        .font(.damaLabel)
                        .foregroundColor(.damaInk)
                    
                    if let createdAt = comment.createdAt {
                        Text(createdAt.relativeKoreanString)
                            .font(.damaMicro)
                            .foregroundColor(.damaInkSubtle)
                    }
                }
                
                Text(comment.text)
                    .font(.damaBody)
                    .foregroundColor(.damaInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
            
            if isMine {
                Menu {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(.damaInkSubtle)
                        .frame(width: 24, height: 24)
                }
            }
        }
        .confirmationDialog(
            "이 댓글을 삭제할까요?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("삭제", role: .destructive, action: onDelete)
            Button("취소", role: .cancel) { }
        }
    }
    
    private var avatarInitial: String {
        String(comment.userName.prefix(1))
    }
    
    private let _PrimaryCream = Color(red: 251/255, green: 244/255, blue: 229/255)
}

// MARK: - Preview

#Preview {
    CommentsSheet(
        photo: Photo(
            id: "p1",
            groupId: "g1",
            uploaderId: "me",
            uploaderName: "승수",
            storagePath: "",
            thumbnailPath: nil,
            caption: nil,
            width: 1,
            height: 1,
            likeCount: 0,
            likedBy: [],
            commentCount: 0
        )
    )
    .environmentObject(AuthViewModel())
}
