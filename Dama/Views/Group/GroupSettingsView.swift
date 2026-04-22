//
//  GroupSettingsView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/22/26.
//
//  그룹 정보·멤버 목록·초대 코드·나가기·삭제.

import SwiftUI
import FirebaseCore

struct GroupSettingsView: View {
    
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var viewModel: GroupSettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    let onGroupRemoved: (String) -> Void
    
    @State private var showLeaveConfirm = false
    @State private var showDeleteConfirm = false
    @State private var showRegenerateConfirm = false
    @State private var copiedInviteCode = false
    @State private var isPresentingEdit = false
    @State private var isPresentingTransfer = false
    @State private var toastMessage: String?
    
    init(group: DamaGroup, onGroupRemoved: @escaping (String) -> Void = { _ in }) {
        _viewModel = StateObject(wrappedValue: GroupSettingsViewModel(group: group))
        self.onGroupRemoved = onGroupRemoved
    }
    
    var body: some View {
        ZStack {
            Color.damaCream.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: DamaSpacing.xl) {
                    groupSummary
                    inviteCodeSection
                    if isOwner {
                        ownerActionsSection
                    }
                    membersSection
                    dangerZone
                }
                .padding(.horizontal, DamaSpacing.lg)
                .padding(.vertical, DamaSpacing.lg)
            }
            
            if let msg = toastMessage {
                toastBanner(msg)
            }
        }
        .navigationTitle("그룹 설정")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadMembers()
        }
        .sheet(isPresented: $isPresentingEdit) {
            EditGroupView(settingsViewModel: viewModel)
                .environmentObject(auth)
        }
        .sheet(isPresented: $isPresentingTransfer) {
            TransferOwnershipSheet(settingsViewModel: viewModel)
                .environmentObject(auth)
        }
        .confirmationDialog(
            "그룹에서 나갈까요?",
            isPresented: $showLeaveConfirm,
            titleVisibility: .visible
        ) {
            Button("나가기", role: .destructive) {
                Task { await performLeave() }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("다시 들어오려면 초대 코드가 필요해요")
        }
        .confirmationDialog(
            "그룹을 삭제할까요?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("삭제", role: .destructive) {
                Task { await performDelete() }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("모든 사진과 추억이 사라지고, 되돌릴 수 없어요")
        }
        .confirmationDialog(
            "초대 코드를 새로 발급할까요?",
            isPresented: $showRegenerateConfirm,
            titleVisibility: .visible
        ) {
            Button("새 코드 발급", role: .destructive) {
                Task { await performRegenerate() }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("기존 코드로는 더 이상 참여할 수 없어요")
        }
        .alert("앗", isPresented: errorBinding) {
            Button("확인", role: .cancel) { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - Sections
    
    private var groupSummary: some View {
        HStack(spacing: DamaSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: DamaRadius.md)
                    .fill(Color.damaColor(for: viewModel.group.id ?? viewModel.group.name))
                    .frame(width: 64, height: 64)
                
                if let emoji = viewModel.group.coverEmoji {
                    Text(emoji)
                        .font(.system(size: 32))
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.group.name)
                    .font(.damaTitle)
                    .foregroundColor(.damaInk)
                
                Text("\(viewModel.group.memberCount)명 · 사진 \(viewModel.group.photoCount)장")
                    .font(.damaCaption)
                    .foregroundColor(.damaInkMuted)
                
                if let createdAt = viewModel.group.createdAt {
                    Text(formatCreatedDate(createdAt.dateValue()))
                        .font(.damaMicro)
                        .foregroundColor(.damaInkSubtle)
                }
            }
            
            Spacer()
            
            if isOwner {
                Button {
                    isPresentingEdit = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.damaCoral)
                        .frame(width: 32, height: 32)
                        .background(Color.damaCoral.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
    }
    
    private var inviteCodeSection: some View {
        VStack(alignment: .leading, spacing: DamaSpacing.sm) {
            Text("초대 코드")
                .font(.damaLabel)
                .foregroundColor(.damaInkMuted)
            
            HStack(spacing: DamaSpacing.md) {
                Text(viewModel.group.inviteCode)
                    .font(.system(size: 22, weight: .medium, design: .monospaced))
                    .foregroundColor(.damaInk)
                    .tracking(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button {
                    UIPasteboard.general.string = viewModel.group.inviteCode
                    withAnimation { copiedInviteCode = true }
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        withAnimation { copiedInviteCode = false }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copiedInviteCode ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12))
                        Text(copiedInviteCode ? "복사됨" : "복사")
                            .font(.damaCaption)
                    }
                    .foregroundColor(.damaCoral)
                    .padding(.vertical, 6)
                    .padding(.horizontal, DamaSpacing.md)
                    .background(Color.damaCoral.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                ShareLink(item: inviteShareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundColor(.damaCoral)
                        .padding(.vertical, 8)
                        .padding(.horizontal, DamaSpacing.md)
                        .background(Color.damaCoral.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(DamaSpacing.md)
            .background(Color.damaCreamWarm)
            .clipShape(RoundedRectangle(cornerRadius: DamaRadius.md))
        }
    }
    
    private var ownerActionsSection: some View {
        VStack(alignment: .leading, spacing: DamaSpacing.sm) {
            Text("관리")
                .font(.damaLabel)
                .foregroundColor(.damaInkMuted)
            
            VStack(spacing: 0) {
                actionRow(
                    icon: "arrow.clockwise",
                    title: "초대 코드 새로 발급",
                    subtitle: "기존 코드로는 참여 불가"
                ) {
                    showRegenerateConfirm = true
                }
                
                Divider()
                    .background(Color.damaDivider)
                    .padding(.leading, 52)
                
                actionRow(
                    icon: "crown",
                    title: "그룹장 권한 넘기기",
                    subtitle: "다른 멤버를 그룹장으로 지정"
                ) {
                    isPresentingTransfer = true
                }
            }
            .background(Color.damaCreamWarm)
            .clipShape(RoundedRectangle(cornerRadius: DamaRadius.md))
        }
    }
    
    private func actionRow(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: DamaSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.damaCoral)
                    .frame(width: 28, height: 28)
                    .background(Color.damaCoral.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.damaLabel)
                        .foregroundColor(.damaInk)
                    Text(subtitle)
                        .font(.damaMicro)
                        .foregroundColor(.damaInkSubtle)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.damaInkSubtle)
            }
            .padding(.horizontal, DamaSpacing.md)
            .padding(.vertical, DamaSpacing.md)
        }
        .buttonStyle(.plain)
    }
    
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: DamaSpacing.sm) {
            HStack {
                Text("멤버")
                    .font(.damaLabel)
                    .foregroundColor(.damaInkMuted)
                Spacer()
                Text("\(viewModel.members.count) / \(DamaGroup.maxMembers)")
                    .font(.damaCaption)
                    .foregroundColor(.damaInkSubtle)
            }
            
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView().tint(.damaCoral)
                    Spacer()
                }
                .padding(.vertical, DamaSpacing.lg)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.members.enumerated()), id: \.element.id) { index, member in
                        MemberRow(
                            member: member,
                            isCurrentUser: member.userId == (auth.currentUser?.id ?? ""),
                            canRemove: isOwner && member.userId != (auth.currentUser?.id ?? ""),
                            onRemove: {
                                Task { await performRemoveMember(target: member) }
                            }
                        )
                        
                        if index < viewModel.members.count - 1 {
                            Divider()
                                .background(Color.damaDivider)
                                .padding(.leading, 52)
                        }
                    }
                }
                .background(Color.damaCreamWarm)
                .clipShape(RoundedRectangle(cornerRadius: DamaRadius.md))
            }
        }
    }
    
    private var dangerZone: some View {
        VStack(spacing: DamaSpacing.sm) {
            if isOwner {
                DamaButton("그룹 삭제", variant: .secondary, fullWidth: true) {
                    showDeleteConfirm = true
                }
            } else {
                DamaButton("그룹 나가기", variant: .secondary, fullWidth: true) {
                    showLeaveConfirm = true
                }
            }
            
            if isOwner {
                Text("그룹장이시군요. 다른 멤버에게 권한을 넘기면 나갈 수 있어요")
                    .font(.damaMicro)
                    .foregroundColor(.damaInkSubtle)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, DamaSpacing.lg)
    }
    
    // MARK: - Toast
    
    private func toastBanner(_ message: String) -> some View {
        VStack {
            Spacer()
            Text(message)
                .font(.damaCaption)
                .foregroundColor(_PrimaryCream)
                .padding(.horizontal, DamaSpacing.lg)
                .padding(.vertical, DamaSpacing.sm)
                .background(Color.damaInk.opacity(0.9))
                .clipShape(Capsule())
                .padding(.bottom, DamaSpacing.xl)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Helpers
    
    private var isOwner: Bool {
        viewModel.isOwner(uid: auth.currentUser?.id ?? "")
    }
    
    private var inviteShareText: String {
        """
        📷 담아에서 『\(viewModel.group.name)』 앨범에 초대할게!
        
        아래 코드를 앱에서 입력하면 돼.
        
        \(viewModel.group.inviteCode)
        """
    }
    
    private func formatCreatedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일 시작"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )
    }
    
    private func performLeave() async {
        guard let uid = auth.currentUser?.id,
              let groupId = viewModel.group.id else { return }
        if await viewModel.leave(uid: uid) {
            onGroupRemoved(groupId)
            dismiss()
        }
    }
    
    private func performDelete() async {
        guard let uid = auth.currentUser?.id,
              let groupId = viewModel.group.id else { return }
        if await viewModel.delete(uid: uid) {
            onGroupRemoved(groupId)
            dismiss()
        }
    }
    
    private func performRegenerate() async {
        guard let uid = auth.currentUser?.id else { return }
        if let newCode = await viewModel.regenerateInviteCode(ownerUid: uid) {
            showToast("새 초대 코드: \(newCode)")
        }
    }
    
    private func performRemoveMember(target: GroupMember) async {
        guard let ownerUid = auth.currentUser?.id else { return }
        
        if await viewModel.removeMember(targetUid: target.userId, ownerUid: ownerUid) {
            showToast("\(target.displayName)님을 내보냈어요")
        }
    }
    
    private func showToast(_ message: String) {
        withAnimation(.easeOut(duration: 0.25)) {
            toastMessage = message
        }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.easeOut(duration: 0.25)) {
                toastMessage = nil
            }
        }
    }
    
    private let _PrimaryCream = Color(red: 251/255, green: 244/255, blue: 229/255)
}

// MARK: - Member Row

private struct MemberRow: View {
    
    let member: GroupMember
    let isCurrentUser: Bool
    let canRemove: Bool
    let onRemove: () -> Void
    
    @State private var showRemoveConfirm = false
    
    var body: some View {
        HStack(spacing: DamaSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.damaColor(for: member.userId))
                    .frame(width: 36, height: 36)
                
                Text(avatarInitial)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(_PrimaryCream)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(member.displayName)
                        .font(.damaLabel)
                        .foregroundColor(.damaInk)
                    
                    if isCurrentUser {
                        Text("나")
                            .font(.damaMicro)
                            .foregroundColor(.damaInkSubtle)
                    }
                }
                
                if member.isOwner {
                    Text("그룹장")
                        .font(.damaMicro)
                        .foregroundColor(.damaCoral)
                }
            }
            
            Spacer()
            
            if canRemove {
                Menu {
                    Button(role: .destructive) {
                        showRemoveConfirm = true
                    } label: {
                        Label("내보내기", systemImage: "person.fill.xmark")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(.damaInkSubtle)
                        .frame(width: 28, height: 28)
                }
            } else if let joinedAt = member.joinedAt {
                Text(joinedAt.relativeKoreanString)
                    .font(.damaMicro)
                    .foregroundColor(.damaInkSubtle)
            }
        }
        .padding(.horizontal, DamaSpacing.md)
        .padding(.vertical, DamaSpacing.md)
        .confirmationDialog(
            "\(member.displayName)님을 내보낼까요?",
            isPresented: $showRemoveConfirm,
            titleVisibility: .visible
        ) {
            Button("내보내기", role: .destructive) {
                onRemove()
            }
            Button("취소", role: .cancel) { }
        }
    }
    
    private var avatarInitial: String {
        String(member.displayName.prefix(1))
    }
    
    private let _PrimaryCream = Color(red: 251/255, green: 244/255, blue: 229/255)
}
