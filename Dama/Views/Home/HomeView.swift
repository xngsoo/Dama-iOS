//
//  HomeView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  로그인 후 첫 진입 화면. 그룹 리스트 + 상단 헤더.
//  Phase 6b에서 새 그룹 만들기 시트 연결, Phase 3c에서 실데이터 연결.

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var viewModel = HomeViewModel()
    
    // Phase 6b에서 네비게이션 연결
    @State private var isPresentingCreateGroup = false
    @State private var isPresentingJoinGroup = false
    
    var body: some View {
        ZStack {
            Color.damaCream.ignoresSafeArea()
            
            content
        }
        .task {
            if viewModel.groups.isEmpty {
                await viewModel.loadGroups()
            }
        }
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.groups.isEmpty {
            ProgressView()
                .tint(.damaCoral)
        } else if viewModel.groups.isEmpty {
            EmptyStateView(
                onCreateGroup: { isPresentingCreateGroup = true },
                onJoinGroup: { isPresentingJoinGroup = true }
            )
        } else {
            listContent
        }
    }
    
    // MARK: - List
    
    private var listContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                
                // MARK: Header
                header
                    .padding(.horizontal, DamaSpacing.lg)
                    .padding(.top, DamaSpacing.sm)
                    .padding(.bottom, DamaSpacing.lg)
                
                // MARK: Section Title + Add
                HStack {
                    Text("우리만의 공간")
                        .font(.damaLabel)
                        .foregroundColor(.damaInkMuted)
                    
                    Spacer()
                    
                    Button {
                        isPresentingCreateGroup = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.damaCoral)
                            .frame(width: 28, height: 28)
                    }
                }
                .padding(.horizontal, DamaSpacing.lg)
                .padding(.bottom, DamaSpacing.sm)
                
                // MARK: Groups
                LazyVStack(spacing: DamaSpacing.sm) {
                    ForEach(viewModel.groups) { group in
                        GroupRowView(group: group) {
                            // Phase 7에서 그룹 상세 네비게이션
                            print("Tapped: \(group.name)")
                        }
                    }
                }
                .padding(.horizontal, DamaSpacing.lg)
                .padding(.bottom, DamaSpacing.xl)
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.damaTitle)
                    .foregroundColor(.damaInk)
                
                Text("오늘도 따스한 하루")
                    .font(.damaCaption)
                    .foregroundColor(.damaInkMuted)
            }
            
            Spacer()
            
            // TODO: Phase 7 — 알림/프로필 버튼
            Button {
                auth.signOut()
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.damaInk)
            }
        }
    }
    
    private var greeting: String {
        let name = auth.currentUser?.name ?? "안녕하세요"
        return "안녕, \(name)"
    }
}

// MARK: - Preview

#Preview("With Groups") {
    HomeView()
        .environmentObject(AuthViewModel())
}

#Preview("Empty State") {
    struct EmptyPreview: View {
        var body: some View {
            EmptyStateView(onCreateGroup: { }, onJoinGroup: { })
                .background(Color.damaCream.ignoresSafeArea())
        }
    }
    return EmptyPreview()
}
