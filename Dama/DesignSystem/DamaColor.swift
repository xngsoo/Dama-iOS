//
//  DamaColor.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//

import SwiftUI

extension Color {
    
    // MARK: - Surface (배경·카드면)
    static let damaCream      = Color(hex: "F5EDDF")   // 앱 기본 배경
    static let damaCreamWarm  = Color(hex: "FBF4E5")   // 카드·입력란
    static let damaCreamDim   = Color(hex: "EFE4D0")   // Rewind 모드
    
    // MARK: - Ink (텍스트 계조)
    static let damaInk        = Color(hex: "3E2E21")   // 본문·헤드라인
    static let damaInkMuted   = Color(hex: "7A6654")   // 보조 설명
    static let damaInkSubtle  = Color(hex: "A89880")   // 플레이스홀더
    
    // MARK: - Accent (포인트·CTA)
    static let damaCoral      = Color(hex: "D4734A")   // 주요 액션
    static let damaCoralDeep  = Color(hex: "A8562F")   // 눌림 상태
    static let damaHoney      = Color(hex: "EFD89A")   // 하이라이트
    
    // MARK: - Tag Ramp (그룹·사진 카테고리)
    static let damaSage       = Color(hex: "9BA87D")
    static let damaOlive      = Color(hex: "7A8471")
    static let damaCaramel    = Color(hex: "C8946B")
    static let damaTerracotta = Color(hex: "B6826E")
    static let damaMustard    = Color(hex: "CE9B6A")
    static let damaSand       = Color(hex: "D9B380")
    
    /// 그룹 멤버 아바타·사진 태그 색상 자동 배정용 ramp.
    /// userId.hashValue 등으로 인덱싱해 사용하세요.
    static let damaTagRamp: [Color] = [
        .damaCoral, .damaSage, .damaCaramel,
        .damaTerracotta, .damaMustard, .damaSand, .damaOlive
    ]
    
    // MARK: - Utility (경계선)
    static let damaBorder  = Color(red: 62/255, green: 46/255, blue: 33/255, opacity: 0.12)
    static let damaDivider = Color(red: 62/255, green: 46/255, blue: 33/255, opacity: 0.08)
    
    // MARK: - Hex Initializer
    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch trimmed.count {
        case 6: (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8: (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
