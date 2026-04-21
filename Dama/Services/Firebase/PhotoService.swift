//
//  PhotoService.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  Phase 3c-②a: fetch 구현
//  Phase 3c-②b: upload 추가 예정

import Foundation
import FirebaseFirestore
import FirebaseStorage

@MainActor
final class PhotoService {
    
    static let shared = PhotoService()
    private init() {}
    
    // MARK: - Fetch
    
    /// 그룹의 모든 사진, 최신순.
    func fetchPhotos(groupId: String, limit: Int = 100) async throws -> [Photo] {
        do {
            let snapshot = try await FirestoreCollection.photos(groupId: groupId)
                .order(by: "uploadedAt", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            return try snapshot.documents.compactMap { doc in
                try doc.data(as: Photo.self)
            }
        } catch {
            throw PhotoError.firestoreFailure(error)
        }
    }
    
    // MARK: - Storage Download URL
    
    /// Storage 경로로부터 접근 가능한 다운로드 URL 획득.
    /// Cloud Storage는 signed URL을 반환하므로 토큰이 포함됨.
    /// AsyncImage가 이 URL로 이미지를 바로 로드 가능.
    func downloadURL(storagePath: String) async throws -> URL {
        do {
            let ref = Storage.storage().reference(withPath: storagePath)
            return try await ref.downloadURL()
        } catch {
            throw PhotoError.storageFailure(error)
        }
    }
}
