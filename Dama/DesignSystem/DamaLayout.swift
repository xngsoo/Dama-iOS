//
//  DamaLayout.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//
//  모든 간격·둥글기는 이 enum을 통해 사용합니다.
//  Magic number를 뷰 코드에 직접 쓰지 마세요.

import CoreGraphics

/// 모서리 둥글기 (4pt 단위)
enum DamaRadius {
    static let sm:   CGFloat = 4    // 태그·작은 칩
    static let md:   CGFloat = 10   // 카드·버튼
    static let lg:   CGFloat = 16   // 모달·바텀시트
    static let full: CGFloat = 20   // Pill CTA
}

/// 간격 (4pt 그리드)
enum DamaSpacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 24
    static let xxl: CGFloat = 32
}
