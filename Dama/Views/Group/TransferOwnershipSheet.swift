//
//  TransferOwnershipSheet.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/22/26.
//
//  dama — Select New Owner

import SwiftUI

struct TransferOwnershipSheet: View {
    
    @EnvironmentObject private var auth: AuthViewModel
    @ObservedObject var settingsViewModel: GroupSettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMember: GroupMember?
    @State private var showConfirm = false
    @State private var isTransferring = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.damaCream.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    infoBanner
                    
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(eligibleMembers, id: \.id) { member in
                                Button {
                                    selectedMember = member
                                    showConfirm = true
                                } label: {
                                    memberRow(member)
                                }
                                .buttonStyle(.plain)
                                
                                if member.id != eligibleMembers.last?.id {
                                    Divider()
                                        .background(Color.damaDivider)
                                        .padding(.leading, 52 + DamaSpacing.lg)
                                }
                            }
                        }
                        .background(Color.damaCreamWarm)
                        .clipShape(RoundedRectangle(cornerRadius: DamaRadius.md))
                        .padding(.horizontal, DamaSpacing.lg)
                        .padding(.top, DamaSpacing.md)
                    }
                    
                    if eligibleMembers.isEmpty {
                        emptyView
                    }
                }
            }
            .navigationTitle("그룹장 이양")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                        .foregroundColor(.damaInkMuted)
                }
            }
        }
        .confirmationDialog(
            confirmMessage,
            isPresented: $showConfirm,
            titleVisibility: .visible
        ) {
            Button("이양하기", role: .destructive) {
                Task { await performTransfer() }
            }
            Button("취소", role: .cancel) {
                selectedMember = nil
            }
        }
    }
    
    // MARK: - Subviews
    
    private var infoBanner: some View {
        HStack(spacing: DamaSpacing.sm) {
            Image(systemName: "info.circle")
                .foregroundColor(.damaCoral)
            Text("이양 후에는 본인이 일반 멤버가 되어\n그룹 관리 권한이 사라져요")
                .font(.damaCaption)
                .foregroundColor(.damaInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DamaSpacing.md)
        .background(Color.damaCoral.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: DamaRadius.md))
        .padding(.horizontal, DamaSpacing.lg)
        .padding(.top, DamaSpacing.md)
    }
    
    private func memberRow(_ member: GroupMember) -> some View {
        HStack(spacing: DamaSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.damaColor(for: member.userId))
                    .frame(width: 36, height: 36)
                Text(String(member.displayName.prefix(1)))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(_PrimaryCream)
            }
            
            Text(member.displayName)
                .font(.damaLabel)
                .foregroundColor(.damaInk)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.damaInkSubtle)
        }
        .padding(.horizontal, DamaSpacing.md)
        .padding(.vertical, DamaSpacing.md)
    }
    
    private var emptyView: some View {
        VStack(spacing: DamaSpacing.sm) {
            Spacer()
            Image(systemName: "person.2")
                .font(.system(size: 32))
                .foregroundColor(.damaInkSubtle)
            Text("이양할 멤버가 없어요")
                .font(.damaSubheadline)
                .foregroundColor(.damaInk)
            Text("다른 멤버를 먼저 초대해주세요")
                .font(.damaCaption)
                .foregroundColor(.damaInkMuted)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(DamaSpacing.xl)
    }
    
    // MARK: - Data
    
    private var eligibleMembers: [GroupMember] {
        let me = auth.currentUser?.id ?? ""
        return settingsViewModel.members.filter { $0.userId != me }
    }
    
    private var confirmMessage: String {
        if let name = selectedMember?.displayName {
            return "\(name)님에게 그룹장을\n이양할까요?"
        }
        return "그룹장을 이양할까요?"
    }
    
    private func performTransfer() async {
        guard let member = selectedMember,
              let currentUid = auth.currentUser?.id else { return }
        isTransferring = true
        defer { isTransferring = false }
        
        if await settingsViewModel.transferOwnership(
            to: member.userId,
            currentOwnerUid: currentUid
        ) {
            dismiss()
        }
    }
    
    private let _PrimaryCream = Color(red: 251/255, green: 244/255, blue: 229/255)
}
