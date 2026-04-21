//
//  GroupDetailViewModel.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  dama — Group Detail Screen State

import Combine
import Foundation

@MainActor
final class GroupDetailViewModel: ObservableObject {

    // MARK: - Published

    @Published private(set) var photos: [Photo] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // MARK: - Input

    let group: DamaGroup

    init(group: DamaGroup) {
        self.group = group
    }

    // MARK: - Load

    func loadPhotos() async {
        guard let groupId = group.id else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            photos = try await PhotoService.shared.fetchPhotos(groupId: groupId)
        } catch let error as PhotoError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = PhotoError.firestoreFailure(error).errorDescription
        }
    }

    // MARK: - Insert (업로드 직후 로컬 반영)

    /// 새로 업로드한 사진들을 그리드 최상단에 추가.
    /// Firestore 재조회 없이 즉시 UI에 반영.
    func prependUploaded(_ photos: [Photo]) {
        photos.forEach { photo in
            if !self.photos.contains(where: { $0.id == photo.id }) {
                self.photos.insert(photo, at: 0)
            }
        }
    }

    // MARK: - Remove (삭제 반영)
    /// PhotoDetailView에서 사진이 삭제됐을 때 그리드에서 즉시 제거.
    func didDeletePhoto(id: String) {
        photos.removeAll { $0.id == id }
    }

    func refresh() async {
        await loadPhotos()
    }

    func clearError() {
        errorMessage = nil
    }
}
