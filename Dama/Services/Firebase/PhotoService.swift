//
//  PhotoService.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  dama — Photo CRUD Service

import Foundation
import UIKit
import FirebaseFirestore
import FirebaseStorage

@MainActor
final class PhotoService {
    
    static let shared = PhotoService()
    private init() {}
    
    // MARK: - Config
    
    private static let originalMaxDimension: CGFloat = 2048
    private static let thumbnailMaxDimension: CGFloat = 400
    private static let originalJPEGQuality: CGFloat = 0.85
    private static let thumbnailJPEGQuality: CGFloat = 0.75
    
    // MARK: - Fetch
    
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
    
    // MARK: - Download URL
    
    func downloadURL(storagePath: String) async throws -> URL {
        do {
            let ref = Storage.storage().reference(withPath: storagePath)
            return try await ref.downloadURL()
        } catch {
            throw PhotoError.storageFailure(error)
        }
    }
    
    // MARK: - Upload
    
    /// 이미지 한 장을 Storage에 업로드하고 Firestore Photo 문서를 생성.
    /// 그룹의 photoCount/lastPhotoAt도 트랜잭션으로 동시 갱신.
    ///
    /// - Returns: 생성된 Photo 문서 (ID 포함)
    func uploadPhoto(
        image: UIImage,
        caption: String? = nil,
        groupId: String,
        uploader: User
    ) async throws -> Photo {
        guard let uploaderId = uploader.id, !uploaderId.isEmpty else {
            throw PhotoError.notAuthenticated
        }
        
        // 1. 이미지 처리 (원본 리사이즈 + 썸네일)
        let processedOriginal = image.resized(maxDimension: Self.originalMaxDimension)
        let thumbnail = image.resized(maxDimension: Self.thumbnailMaxDimension)
        
        guard let originalData = processedOriginal.jpegData(quality: Self.originalJPEGQuality),
              let thumbnailData = thumbnail.jpegData(quality: Self.thumbnailJPEGQuality) else {
            throw PhotoError.imageProcessingFailed
        }
        
        // 2. photoId 미리 확정 (Storage 경로 생성용)
        let photoRef = FirestoreCollection.photos(groupId: groupId).document()
        let photoId = photoRef.documentID
        
        let originalPath = StoragePath.photoOriginalPath(groupId: groupId, photoId: photoId)
        let thumbnailPath = StoragePath.photoThumbnailPath(groupId: groupId, photoId: photoId)
        
        // 3. Storage 업로드 (병렬)
        do {
            async let thumbUpload = uploadToStorage(data: thumbnailData, path: thumbnailPath)
            async let originalUpload = uploadToStorage(data: originalData, path: originalPath)
            _ = try await (thumbUpload, originalUpload)
        } catch {
            throw PhotoError.uploadFailed(error)
        }
        
        // 4. Firestore Photo 문서 + 그룹 카운터 업데이트 (트랜잭션)
        let photo = Photo(
            id: photoId,
            groupId: groupId,
            uploaderId: uploaderId,
            uploaderName: uploader.name,
            storagePath: originalPath,
            thumbnailPath: thumbnailPath,
            caption: caption?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            width: Int(processedOriginal.size.width),
            height: Int(processedOriginal.size.height),
            likeCount: 0,
            commentCount: 0,
            uploadedAt: Timestamp(date: Date()),
            takenAt: nil
        )
        
        let groupRef = FirestoreCollection.group(groupId)
        let db = Firestore.firestore()
        
        do {
            _ = try await db.runTransaction { transaction, errorPointer in
                do {
                    try transaction.setData(from: photo, forDocument: photoRef)
                    transaction.updateData([
                        "photoCount": FieldValue.increment(Int64(1)),
                        "lastPhotoAt": FieldValue.serverTimestamp(),
                        "updatedAt": FieldValue.serverTimestamp(),
                    ], forDocument: groupRef)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
                return nil
            }
        } catch {
            // Firestore 실패 시 Storage에 남은 파일 정리 시도 (best-effort)
            try? await deleteStorageFile(path: originalPath)
            try? await deleteStorageFile(path: thumbnailPath)
            throw PhotoError.firestoreFailure(error)
        }
        
        return photo
    }
    
    // MARK: - Storage Helpers
    
    private func uploadToStorage(data: Data, path: String) async throws -> StorageMetadata {
        let ref = Storage.storage().reference(withPath: path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        return try await ref.putDataAsync(data, metadata: metadata)
    }
    
    private func deleteStorageFile(path: String) async throws {
        try await Storage.storage().reference(withPath: path).delete()
    }
}

// MARK: - String Helper

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
