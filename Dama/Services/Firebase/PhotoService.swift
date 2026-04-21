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
            likedBy: [],
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
    
    // MARK: - Like
    /// 좋아요 상태 변경.
    /// - Parameter currentlyLiked: 현재 유저가 이미 좋아요를 눌렀는지 (호출자가 판정).
    /// - Returns: 변경 후 liked 여부.
    func setLike(
        photo: Photo,
        uid: String,
        currentlyLiked: Bool
    ) async throws -> Bool {
        guard let photoId = photo.id else {
            throw PhotoError.photoNotFound
        }
        let ref = FirestoreCollection.photos(groupId: photo.groupId).document(photoId)
        
        do {
            if currentlyLiked {
                try await ref.updateData([
                    "likedBy": FieldValue.arrayRemove([uid]),
                    "likeCount": FieldValue.increment(Int64(-1)),
                ])
                return false
            } else {
                try await ref.updateData([
                    "likedBy": FieldValue.arrayUnion([uid]),
                    "likeCount": FieldValue.increment(Int64(1)),
                ])
                return true
            }
        } catch {
            throw PhotoError.firestoreFailure(error)
        }
    }
    
    // MARK: - Delete
    /// 사진 삭제. Firestore 문서 + 서브컬렉션(comments) + Storage 파일을 정리.
    ///
    /// 권한 체크는 보안 규칙에 위임. 클라이언트에서도 방어적으로 확인하려면
    /// photo.uploaderId 또는 group.ownerId 비교 후 호출.
    func deletePhoto(_ photo: Photo) async throws {
        guard let photoId = photo.id else {
            throw PhotoError.photoNotFound
        }
        
        let photoRef = FirestoreCollection.photos(groupId: photo.groupId).document(photoId)
        let groupRef = FirestoreCollection.group(photo.groupId)
        let db = Firestore.firestore()
        
        // 1. 댓글 서브컬렉션 먼저 일괄 삭제 (트랜잭션 밖)
        //    트랜잭션은 서브컬렉션을 재귀 삭제 못함.
        await deleteCommentsSubcollection(groupId: photo.groupId, photoId: photoId)
        
        // 2. Firestore Photo 문서 + group.photoCount 동시 갱신 (트랜잭션)
        do {
            _ = try await db.runTransaction { transaction, _ in
                transaction.deleteDocument(photoRef)
                transaction.updateData([
                    "photoCount": FieldValue.increment(Int64(-1)),
                    "updatedAt": FieldValue.serverTimestamp(),
                ], forDocument: groupRef)
                return nil
            }
        } catch {
            throw PhotoError.firestoreFailure(error)
        }
        
        // 3. Storage 파일 정리 (best-effort, 실패해도 swallow)
        try? await deleteStorageFile(path: photo.storagePath)
        if let thumbPath = photo.thumbnailPath {
            try? await deleteStorageFile(path: thumbPath)
        }
    }
    
    /// 댓글 서브컬렉션 문서들을 페이지 단위로 삭제.
    /// 1000개 이상이면 반복.
    private func deleteCommentsSubcollection(groupId: String, photoId: String) async {
        let commentsRef = FirestoreCollection.comments(groupId: groupId, photoId: photoId)
        
        while true {
            do {
                let snapshot = try await commentsRef.limit(to: 100).getDocuments()
                if snapshot.documents.isEmpty { return }
                
                let batch = Firestore.firestore().batch()
                for doc in snapshot.documents {
                    batch.deleteDocument(doc.reference)
                }
                try await batch.commit()
                
                if snapshot.documents.count < 100 { return }  // 마지막 페이지
            } catch {
                #if DEBUG
                print("⚠️ 댓글 서브컬렉션 삭제 실패: \(error.localizedDescription)")
                #endif
                return  // 실패하면 포기하고 메인 삭제는 진행
            }
        }
    }
    
    // MARK: - Listen
    /// 단일 사진 문서를 실시간 구독.
    /// 좋아요·댓글 카운트 등이 다른 유저에 의해 변경될 때 즉시 반영용.
    func listenPhoto(
        groupId: String,
        photoId: String,
        onUpdate: @escaping (Photo) -> Void,
        onError: @escaping (Error) -> Void
    ) -> ListenerRegistration {
        return FirestoreCollection.photos(groupId: groupId).document(photoId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    onError(error)
                    return
                }
                guard let snapshot = snapshot, snapshot.exists else { return }
                if let photo = try? snapshot.data(as: Photo.self) {
                    onUpdate(photo)
                }
            }
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
