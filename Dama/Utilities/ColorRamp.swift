//
//  ColorRamp.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  Tag Ramp에서 문자열 기반으로 일관된 색상을 선택.
//  같은 입력 → 항상 같은 색 (앱 재시작·다른 기기에서도 동일).

import SwiftUI

extension Color {
    
    /// 문자열로부터 결정적 Tag Ramp 색 선택.
    /// userId, groupId 등 안정적인 식별자를 넣으면 매번 같은 색 반환.
    static func damaColor(for seed: String) -> Color {
        guard !damaTagRamp.isEmpty else { return .damaCoral }
        let hash = abs(seed.hashValue)
        return damaTagRamp[hash % damaTagRamp.count]
    }
}
