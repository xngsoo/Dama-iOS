//
//  GroupDetailViewModel.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  dama — Group Detail Screen State

import Foundation
import Combine

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
    
    func refresh() async {
        await loadPhotos()
    }
    
    func clearError() {
        errorMessage = nil
    }
}
