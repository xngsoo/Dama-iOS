//
//  Timestamp+Relative.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  dama — Firestore Timestamp → 한국어 상대 시간

import Foundation
import FirebaseFirestore

extension Timestamp {
    
    /// "방금", "5분 전", "2시간 전", "3일 전", "2주 전", "11.13" 형식.
    var relativeKoreanString: String {
        let interval = Date().timeIntervalSince(dateValue())
        
        if interval < 60 { return "방금" }
        if interval < 3600 { return "\(Int(interval / 60))분 전" }
        if interval < 86400 { return "\(Int(interval / 3600))시간 전" }
        if interval < 86400 * 7 { return "\(Int(interval / 86400))일 전" }
        if interval < 86400 * 30 { return "\(Int(interval / (86400 * 7)))주 전" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "M.d"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: dateValue())
    }
}
