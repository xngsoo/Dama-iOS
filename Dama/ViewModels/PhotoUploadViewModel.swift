//
//  PhotoUploadViewModel.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  여러 장의 이미지를 순차 업로드하면서 진행 상태를 UI에 전달.

import Foundation
import UIKit
import Combine

@MainActor
final class PhotoUploadViewModel: ObservableObject {
    
    // MARK: - State
    
    enum UploadState: Equatable {
        case idle
        case uploading(current: Int, total: Int)
        case completed(successful: Int, failed: Int)
    }
    
    @Published private(set) var state: UploadState = .idle
    @Published private(set) var errorMessage: String?
    
    // MARK: - Upload
    
    /// 여러 이미지를 순차 업로드. 완료된 사진들의 배열을 반환.
    @discardableResult
    func uploadImages(
        _ images: [UIImage],
        groupId: String,
        uploader: User
    ) async -> [Photo] {
        guard !images.isEmpty else { return [] }
        
        state = .uploading(current: 0, total: images.count)
        var uploaded: [Photo] = []
        var failedCount = 0
        
        for (index, image) in images.enumerated() {
            do {
                let photo = try await PhotoService.shared.uploadPhoto(
                    image: image,
                    groupId: groupId,
                    uploader: uploader
                )
                uploaded.append(photo)
            } catch {
                failedCount += 1
                #if DEBUG
                print("🔴 사진 \(index + 1)/\(images.count) 업로드 실패: \(error.localizedDescription)")
                #endif
            }
            state = .uploading(current: index + 1, total: images.count)
        }
        
        state = .completed(successful: uploaded.count, failed: failedCount)
        
        if failedCount > 0 && uploaded.isEmpty {
            errorMessage = "업로드에 실패했어요. 네트워크를 확인해주세요"
        } else if failedCount > 0 {
            errorMessage = "\(failedCount)장 업로드에 실패했어요"
        }
        
        return uploaded
    }
    
    // MARK: - Reset
    
    func reset() {
        state = .idle
        errorMessage = nil
    }
    
    func clearError() {
        errorMessage = nil
    }
}
