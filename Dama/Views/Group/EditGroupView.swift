//
//  EditGroupView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/22/26.
//
//  dama — Edit Group Info Sheet

import SwiftUI

struct EditGroupView: View {
    
    @EnvironmentObject private var auth: AuthViewModel
    @ObservedObject var settingsViewModel: GroupSettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var selectedEmoji: String
    @State private var isSaving = false
    
    @FocusState private var nameFocused: Bool
    
    private let emojiOptions = ["📷", "🥂", "🏡", "🌊", "🌸", "☕️", "🎂", "✈️", "🐾", "🎬"]
    
    init(settingsViewModel: GroupSettingsViewModel) {
        self.settingsViewModel = settingsViewModel
        _name = State(initialValue: settingsViewModel.group.name)
        _selectedEmoji = State(initialValue: settingsViewModel.group.coverEmoji ?? "📷")
    }
    
    private var isValid: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 2 && trimmed.count <= 20
    }
    
    private var hasChanges: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed != settingsViewModel.group.name
            || selectedEmoji != (settingsViewModel.group.coverEmoji ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.damaCream.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: DamaSpacing.xl) {
                            
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
                                            .stroke(nameFocused ? Color.damaCoral : Color.damaBorder,
                                                    lineWidth: nameFocused ? 1 : 0.5)
                                    )
                                    .animation(.easeInOut(duration: 0.15), value: nameFocused)
                                
                                Text("\(name.count) / 20")
                                    .font(.damaMicro)
                                    .foregroundColor(.damaInkSubtle)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            
                            VStack(alignment: .leading, spacing: DamaSpacing.sm) {
                                Text("커버 이모지")
                                    .font(.damaLabel)
                                    .foregroundColor(.damaInkMuted)
                                
                                LazyVGrid(
                                    columns: Array(repeating: GridItem(.flexible(), spacing: DamaSpacing.sm), count: 5),
                                    spacing: DamaSpacing.sm
                                ) {
                                    ForEach(emojiOptions, id: \.self) { emoji in
                                        Button {
                                            selectedEmoji = emoji
                                        } label: {
                                            Text(emoji)
                                                .font(.system(size: 26))
                                                .frame(maxWidth: .infinity)
                                                .aspectRatio(1, contentMode: .fit)
                                                .background(selectedEmoji == emoji
                                                            ? Color.damaCoral.opacity(0.15)
                                                            : Color.damaCreamWarm)
                                                .clipShape(RoundedRectangle(cornerRadius: DamaRadius.md))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: DamaRadius.md)
                                                        .stroke(selectedEmoji == emoji ? Color.damaCoral : .clear,
                                                                lineWidth: 1.5)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DamaSpacing.lg)
                        .padding(.top, DamaSpacing.lg)
                        .padding(.bottom, DamaSpacing.xl)
                    }
                    
                    DamaButton("저장", fullWidth: true, isLoading: isSaving) {
                        Task { await submit() }
                    }
                    .disabled(!isValid || !hasChanges || isSaving)
                    .opacity(isValid && hasChanges ? 1 : 0.5)
                    .padding(.horizontal, DamaSpacing.lg)
                    .padding(.bottom, DamaSpacing.lg)
                }
            }
            .navigationTitle("그룹 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                        .foregroundColor(.damaInkMuted)
                }
            }
        }
        .onAppear { nameFocused = true }
    }
    
    private func submit() async {
        guard let uid = auth.currentUser?.id else { return }
        isSaving = true
        defer { isSaving = false }
        
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if await settingsViewModel.updateInfo(
            name: trimmed,
            coverEmoji: selectedEmoji,
            ownerUid: uid
        ) {
            dismiss()
        }
    }
}
