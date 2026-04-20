//
//  OnboardingView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//
//  처음 실행 시 3페이지 슬라이드로 담아의 시그니처 기능 3가지 소개.
//  완료 시 @AppStorage("hasCompletedOnboarding") = true 설정되어
//  다음 실행부터는 스킵됩니다.

import SwiftUI

struct OnboardingView: View {
    
    let onComplete: () -> Void
    
    @State private var currentPage = 0
    private let pageCount = 3
    
    var body: some View {
        ZStack {
            Color.damaCream.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // MARK: Skip
                HStack {
                    Spacer()
                    DamaButton("건너뛰기", variant: .text) {
                        onComplete()
                    }
                }
                .padding(.horizontal, DamaSpacing.md)
                .padding(.top, DamaSpacing.xs)
                
                // MARK: Pages
                TabView(selection: $currentPage) {
                    page1.tag(0)
                    page2.tag(1)
                    page3.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // MARK: Page Indicator
                HStack(spacing: 7) {
                    ForEach(0..<pageCount, id: \.self) { idx in
                        Capsule()
                            .fill(idx == currentPage ? Color.damaCoral : Color.damaInkSubtle.opacity(0.3))
                            .frame(width: idx == currentPage ? 20 : 6, height: 6)
                            .animation(.easeInOut(duration: 0.25), value: currentPage)
                    }
                }
                .padding(.vertical, DamaSpacing.lg)
                
                // MARK: CTA
                Group {
                    if currentPage == pageCount - 1 {
                        DamaButton("시작하기", fullWidth: true) {
                            onComplete()
                        }
                    } else {
                        DamaButton("다음", fullWidth: true) {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    }
                }
                .padding(.horizontal, DamaSpacing.xl)
                .padding(.bottom, DamaSpacing.xl)
            }
        }
    }
    
    // MARK: - Pages
    
    private var page1: some View {
        OnboardingPage(
            title: "우리끼리만 보는\n작은 앨범",
            description: "단톡에 묻히지 않게, 10명 이하 비공개 그룹으로 함께 쌓아요"
        ) {
            ZStack {
                DamaPhotoTile(rotation: -8) {
                    Color.damaSage.frame(width: 110, height: 110)
                }
                .offset(x: -55, y: 20)
                
                DamaPhotoTile(rotation: 4) {
                    Color.damaCaramel.frame(width: 110, height: 110)
                }
                
                DamaPhotoTile(rotation: -3) {
                    Color.damaCoral.frame(width: 110, height: 110)
                }
                .offset(x: 55, y: -15)
            }
        }
    }
    
    private var page2: some View {
        OnboardingPage(
            title: "매주 일요일,\n이번 주 우리",
            description: "한 주간 모인 사진을 자동으로 큐레이션해 그룹에 공유해드려요"
        ) {
            VStack(spacing: DamaSpacing.md) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.damaCoral)
                        .frame(width: 5, height: 5)
                    Text("이번 주 · 11월 10일 – 16일")
                        .font(.damaCaption)
                        .foregroundColor(.damaInkMuted)
                }
                .padding(.horizontal, DamaSpacing.md)
                .padding(.vertical, DamaSpacing.xs)
                .background(Color.damaCreamWarm)
                .clipShape(Capsule())
                
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        tile(.damaCoral)
                        tile(.damaSage)
                        tile(.damaCaramel)
                    }
                    HStack(spacing: 4) {
                        tile(.damaTerracotta)
                        tile(.damaMustard)
                        tile(.damaSand)
                    }
                }
            }
        }
    }
    
    private var page3: some View {
        OnboardingPage(
            title: "1년 전 오늘,\n그 순간",
            description: "잊고 있던 소중한 기억을 때마다 꺼내 보여드려요"
        ) {
            VStack(spacing: DamaSpacing.md) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.damaCoral)
                        .frame(width: 5, height: 5)
                    Text("1년 전 · 2024.11.13")
                        .font(.damaCaption)
                        .foregroundColor(.damaInkMuted)
                }
                .padding(.horizontal, DamaSpacing.md)
                .padding(.vertical, DamaSpacing.xs)
                .background(Color.damaCreamWarm)
                .clipShape(Capsule())
                
                DamaPhotoTile(caption: "종로 밤거리", rotation: -2) {
                    Color.damaCaramel.frame(width: 140, height: 160)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func tile(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color)
            .frame(width: 52, height: 52)
    }
}

// MARK: - Generic Page Layout

private struct OnboardingPage<Visual: View>: View {
    
    let title: String
    let description: String
    let visual: Visual
    
    init(
        title: String,
        description: String,
        @ViewBuilder visual: () -> Visual
    ) {
        self.title = title
        self.description = description
        self.visual = visual()
    }
    
    var body: some View {
        VStack(spacing: DamaSpacing.xl) {
            Spacer()
            
            visual
                .frame(height: 220)
            
            VStack(spacing: DamaSpacing.md) {
                Text(title)
                    .font(.damaHeadline)
                    .foregroundColor(.damaInk)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                
                Text(description)
                    .font(.damaBody)
                    .foregroundColor(.damaInkMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, DamaSpacing.xl)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Light") {
    OnboardingView(onComplete: { })
}

#Preview("Dark") {
    OnboardingView(onComplete: { })
        .preferredColorScheme(.dark)
}
