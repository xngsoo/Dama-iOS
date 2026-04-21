//
//  UIImage+Resize.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//

import UIKit

extension UIImage {
    
    /// 최대 변 길이를 기준으로 비율 유지 리사이즈.
    /// 원본이 더 작으면 그대로 반환.
    func resized(maxDimension: CGFloat) -> UIImage {
        let longSide = max(size.width, size.height)
        guard longSide > maxDimension else { return self }
        
        let scale = maxDimension / longSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1  // 실제 픽셀 기반 (Retina 스케일 무시)
        format.opaque = true
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// JPEG 데이터로 인코딩.
    func jpegData(quality: CGFloat = 0.85) -> Data? {
        return self.jpegData(compressionQuality: quality)
    }
}
