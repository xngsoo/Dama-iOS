//
//  CreateGroupView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  그룹 이름 + 커버 이모지 선택 → 생성 요청.
//  생성 성공 시 InviteShareView로 전환하여 초대 코드 공유 유도.

import SwiftUI

struct CreateGroupView: View {
    
    @EnvironmentObject private var auth: AuthViewModel
    @ObservedObject var homeViewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedEmoji = "📷"
    @State private var isCreating = false
    @State private var createdGroup: DamaGroup?
    
    @FocusState private var nameFocused: Bool
    
    // MARK: - Emoji options
    private let emojiOptions = ["📷", "🥂", "🏡", "🌊", "🌸", "☕️", "🎂", "✈️", "🐾", "🎬"]
    
    // MARK: - Validation
    private var isValid: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 2 && trimmed.count <= 20
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.damaCream.ignoresSafeArea()
                
                if let createdGroup {
                    InviteShareView(group: createdGroup) {
                        dismiss()
                    }
                } else {
                    formContent
                }
            }
            .navigationTitle(createdGroup == nil ? "새 그룹" : "그룹 만들기 완료")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if createdGroup == nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("취소") { dismiss() }
                            .foregroundColor(.damaInkMuted)
                    }
                }
            }
        }
    }
    
    // MARK: - Form
    
    private var formContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: DamaSpacing.xl) {
                    
                    // MARK: Intro
                    VStack(alignment: .leading, spacing: DamaSpacing.xs) {
                        Text("어떤 기억을 담으실 건가요")
                            .font(.damaSubheadline)
                            .foregroundColor(.damaInk)
                        
                        Text("최대 10명 이하 소중한 사람들과 함께해요")
                            .font(.damaCaption)
                            .foregroundColor(.damaInkMuted)
                    }
                    .padding(.top, DamaSpacing.lg)
                    
                    // MARK: Name
                    VStack(alignment: .leading, spacing: DamaSpacing.sm) {
                        Text("그룹 이름")
                            .font(.damaLabel)
                            .foregroundColor(.damaInkMuted)
                        
                        TextField("예) 찐친클럽", text: $name)
                            .font(.damaTitle)
                            .foregroundColor(.damaInk)
                            .focused($nameFocused)
                            .submitLabel(.done)
                            .padding(.vertical, DamaSpacing.md)
                            .padding(.horizontal, DamaSpacing.md)
                            .background(Color.damaCreamWarm)
                            .clipShape(RoundedRectangle(cornerRadius: DamaRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: DamaRadius.md)
                                    .stroke(nameFocused ? Color.damaCoral : Color.damaBorder, lineWidth: nameFocused ? 1 : 0.5)
                            )
                            .animation(.easeInOut(duration: 0.15), value: nameFocused)
                        
                        Text("\(name.count) / 20")
                            .font(.damaMicro)
                            .foregroundColor(.damaInkSubtle)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    // MARK: Emoji Picker
                    VStack(alignment: .leading, spacing: DamaSpacing.sm) {
                        Text("커버 이모지")
                            .font(.damaLabel)
                            .foregroundColor(.damaInkMuted)
                        
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: DamaSpacing.sm), count: 5),
                            spacing: DamaSpacing.sm
                        ) {
                            ForEach(emojiOptions, id: \.self) { emoji in
                                emojiCell(emoji)
                            }
                        }
                    }
                }
                .padding(.horizontal, DamaSpacing.lg)
                .padding(.bottom, DamaSpacing.xl)
            }
            
            // MARK: CTA
            DamaButton("그룹 만들기", fullWidth: true, isLoading: isCreating) {
                Task { await submit() }
            }
            .disabled(!isValid || isCreating)
            .opacity(isValid ? 1 : 0.5)
            .padding(.horizontal, DamaSpacing.lg)
            .padding(.bottom, DamaSpacing.lg)
        }
        .onAppear { nameFocused = true }
    }
    
    // MARK: - Emoji Cell
    
    private func emojiCell(_ emoji: String) -> some View {
        Button {
            selectedEmoji = emoji
        } label: {
            Text(emoji)
                .font(.system(size: 26))
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(selectedEmoji == emoji ? Color.damaCoral.opacity(0.15) : Color.damaCreamWarm)
                .clipShape(RoundedRectangle(cornerRadius: DamaRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: DamaRadius.md)
                        .stroke(selectedEmoji == emoji ? Color.damaCoral : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Submit
    
    private func submit() async {
        guard let user = auth.currentUser else { return }
        isCreating = true
        defer { isCreating = false }
        
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let group = await homeViewModel.createGroup(
            name: trimmed,
            coverEmoji: selectedEmoji,
            owner: user
        ) {
            nameFocused = false
            createdGroup = group
        }
        // 실패 시 homeViewModel.errorMessage가 설정됨 (알림은 Phase 3c-③에서 정식화)
    }
}

#Preview {
    CreateGroupView(homeViewModel: HomeViewModel())
        .environmentObject(AuthViewModel())
}
