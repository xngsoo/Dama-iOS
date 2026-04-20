//
//  DamaFont.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//
//  담아는 두 폰트 패밀리로 구성됩니다:
//   · Nanum Myeongjo (세리프)  → 감성 카피·헤드라인
//   · Pretendard     (산세리프) → 모든 UI·본문

import SwiftUI

extension Font {
    
    // MARK: - Display (Serif · Nanum Myeongjo)
    static let damaDisplay      = Font.custom("NanumMyeongjo", size: 28)  // 로고·스플래시
    static let damaHeadline     = Font.custom("NanumMyeongjo", size: 22)  // 이번 주 우리 / 1년 전 오늘
    static let damaSubheadline  = Font.custom("NanumMyeongjo", size: 18)  // 감성 캡션
    
    // MARK: - UI (Sans · Pretendard)
    static let damaTitle        = Font.custom("Pretendard-Medium",  size: 17)  // 화면 제목
    static let damaBody         = Font.custom("Pretendard-Regular", size: 15)  // 본문
    static let damaLabel        = Font.custom("Pretendard-Medium",  size: 13)  // 버튼·칩
    static let damaCaption      = Font.custom("Pretendard-Regular", size: 12)  // 메타정보
    static let damaMicro        = Font.custom("Pretendard-Regular", size: 10)  // 타임스탬프
}

// MARK: - 한 줄 적용 ViewModifier
extension View {
    /// 텍스트에 담아 기본 스타일(폰트 + 색상)을 한번에 적용.
    /// 예: Text("이번 주 우리").damaStyle(.damaHeadline, color: .damaInk)
    func damaStyle(_ font: Font, color: Color = .damaInk) -> some View {
        self.font(font).foregroundColor(color)
    }
}
