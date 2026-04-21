//
//  JoinGroupView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  6자리 초대 코드 입력 → 그룹 참여.
//  Phase 3c에서 실제 Firestore 조회로 교체, 현재는 로컬 더미 유효성만 검증.

import SwiftUI

struct JoinGroupView: View {
    
    @ObservedObject var homeViewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var code = ""
    @State private var errorText: String?
    @State private var isJoining = false
    
    @FocusState private var codeFocused: Bool
    
    private var sanitized: String {
        code.uppercased().filter { $0.isLetter || $0.isNumber }
    }
    
    private var isValid: Bool { sanitized.count == 6 }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.damaCream.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: DamaSpacing.xl) {
                            
                            VStack(alignment: .leading, spacing: DamaSpacing.xs) {
                                Text("초대 코드를 입력해주세요")
                                    .font(.damaSubheadline)
                                    .foregroundColor(.damaInk)
                                
                                Text("그룹에서 공유받은 6자리 코드")
                                    .font(.damaCaption)
                                    .foregroundColor(.damaInkMuted)
                            }
                            .padding(.top, DamaSpacing.lg)
                            
                            VStack(spacing: DamaSpacing.sm) {
                                TextField("ABC123", text: $code)
                                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                                    .tracking(6)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.damaInk)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.characters)
                                    .focused($codeFocused)
                                    .padding(.vertical, DamaSpacing.lg)
                                    .background(Color.damaCreamWarm)
                                    .clipShape(RoundedRectangle(cornerRadius: DamaRadius.md))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DamaRadius.md)
                                            .stroke(codeFocused ? Color.damaCoral : Color.damaBorder,
                                                    lineWidth: codeFocused ? 1 : 0.5)
                                    )
                                    .onChange(of: code) { newValue in
                                        let cleaned = newValue.uppercased()
                                            .filter { $0.isLetter || $0.isNumber }
                                        if cleaned != newValue || cleaned.count > 6 {
                                            code = String(cleaned.prefix(6))
                                        }
                                        errorText = nil
                                    }
                                
                                if let errorText {
                                    Text(errorText)
                                        .font(.damaCaption)
                                        .foregroundColor(.damaCoralDeep)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .padding(.horizontal, DamaSpacing.lg)
                        .padding(.bottom, DamaSpacing.xl)
                    }
                    
                    DamaButton("참여하기", fullWidth: true, isLoading: isJoining) {
                        Task { await submit() }
                    }
                    .disabled(!isValid || isJoining)
                    .opacity(isValid ? 1 : 0.5)
                    .padding(.horizontal, DamaSpacing.lg)
                    .padding(.bottom, DamaSpacing.lg)
                }
            }
            .navigationTitle("그룹 참여")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                        .foregroundColor(.damaInkMuted)
                }
            }
        }
        .onAppear { codeFocused = true }
    }
    
    // MARK: - Submit
    
    private func submit() async {
        isJoining = true
        defer { isJoining = false }
        
        let result = await homeViewModel.joinGroup(inviteCode: sanitized)
        switch result {
        case .success:
            dismiss()
        case .notFound:
            errorText = "코드를 찾을 수 없어요. 다시 확인해주세요"
        case .alreadyMember:
            errorText = "이미 참여한 그룹이에요"
        case .full:
            errorText = "그룹이 가득 찼어요 (최대 10명)"
        }
    }
}

#Preview {
    JoinGroupView(homeViewModel: HomeViewModel())
}
