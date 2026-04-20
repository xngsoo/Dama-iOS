//
//  DamaColor.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//
//  DamaColor.swift
//  dama — Design Token: Color
//

import SwiftUI

extension Color {
    
    /// 그룹 멤버 아바타·사진 태그 색 자동 배정용 ramp.
    ///
    /// 사용 예:
    /// ```
    /// let idx = abs(userId.hashValue) % Color.damaTagRamp.count
    /// let avatarColor = Color.damaTagRamp[idx]
    /// ```
    static let damaTagRamp: [Color] = [
        .damaCoral, .damaSage, .damaCaramel,
        .damaTerracotta, .damaMustard, .damaSand, .damaOlive
    ]
}
