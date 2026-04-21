//
//  HomeView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  로그인 후 첫 진입 화면. 그룹 리스트 + 상단 헤더.

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var viewModel = HomeViewModel()
    
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
        .sheet(isPresented: $isPresentingCreateGroup) {
            CreateGroupView(homeViewModel: viewModel)
                .environmentObject(auth)
        }
        .sheet(isPresented: $isPresentingJoinGroup) {
            JoinGroupView(homeViewModel: viewModel)
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
                header
                    .padding(.horizontal, DamaSpacing.lg)
                    .padding(.top, DamaSpacing.sm)
                    .padding(.bottom, DamaSpacing.lg)
                
                sectionTitle
                    .padding(.horizontal, DamaSpacing.lg)
                    .padding(.bottom, DamaSpacing.sm)
                
                LazyVStack(spacing: DamaSpacing.sm) {
                    ForEach(viewModel.groups) { group in
                        GroupRowView(group: group) {
                            print("Tapped: \(group.name)")
                        }
                    }
                }
                .padding(.horizontal, DamaSpacing.lg)
                
                // "참여하기" — 리스트 있을 때의 보조 진입점
                Button {
                    isPresentingJoinGroup = true
                } label: {
                    HStack(spacing: DamaSpacing.xs) {
                        Image(systemName: "link")
                            .font(.system(size: 12))
                        Text("초대 코드로 참여")
                            .font(.damaCaption)
                    }
                    .foregroundColor(.damaInkMuted)
                }
                .padding(.top, DamaSpacing.lg)
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
            
            Button {
                auth.signOut()
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.damaInk)
            }
        }
    }
    
    // MARK: - Section Title
    
    private var sectionTitle: some View {
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
    }
    
    // MARK: - Helpers
    
    private var greeting: String {
        let name = auth.currentUser?.name ?? "안녕하세요"
        return "안녕, \(name)"
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}
