//
//  GroupService.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  Firestore /groups + /inviteCodes 조작.
//  모든 쓰기 작업은 트랜잭션/배치로 정합성 유지.

import Foundation
import FirebaseFirestore

@MainActor
final class GroupService {
    
    static let shared = GroupService()
    private init() {}
    
    private var db: Firestore { Firestore.firestore() }
    
    // MARK: - Fetch
    
    /// 특정 유저가 멤버인 모든 그룹.
    /// 최근 사진 업로드순으로 정렬.
    func fetchGroups(for uid: String) async throws -> [DamaGroup] {
        do {
            let snapshot = try await FirestoreCollection.groups
                .whereField("memberIds", arrayContains: uid)
                .order(by: "updatedAt", descending: true)
                .getDocuments()
            
            return try snapshot.documents.compactMap { doc in
                try doc.data(as: DamaGroup.self)
            }
        } catch {
            throw GroupError.firestoreFailure(error)
        }
    }
    
    /// 단일 그룹 조회.
    func fetchGroup(_ groupId: String) async throws -> DamaGroup {
        do {
            let snapshot = try await FirestoreCollection.group(groupId).getDocument()
            guard snapshot.exists, let group = try snapshot.data(as: DamaGroup?.self) else {
                throw GroupError.groupNotFound
            }
            return group
        } catch let error as GroupError {
            throw error
        } catch {
            throw GroupError.firestoreFailure(error)
        }
    }
    
    // MARK: - Create
    
    /// 새 그룹 생성. 트랜잭션으로 3곳 동시 쓰기:
    ///   1. /groups/{groupId}
    ///   2. /groups/{groupId}/members/{uid}
    ///   3. /inviteCodes/{code} → {groupId}
    ///
    /// 초대 코드 충돌 시 재시도 (최대 3회).
    func createGroup(
        name: String,
        coverEmoji: String?,
        owner: User
    ) async throws -> DamaGroup {
        guard let ownerId = owner.id, !ownerId.isEmpty else {
            throw GroupError.notAuthenticated
        }
        
        // 유니크 초대 코드 확보
        let inviteCode = try await generateUniqueInviteCode(maxAttempts: 3)
        
        let groupRef = FirestoreCollection.groups.document()
        let groupId = groupRef.documentID
        
        var newGroup = DamaGroup.new(name: name, ownerId: ownerId, coverEmoji: coverEmoji)
        newGroup.id = groupId
        newGroup.inviteCode = inviteCode
        // @ServerTimestamp가 적용되지 않을 edge case 대비 — 현재 시각으로 명시 세팅.
        // 서버 쓰기 시 서버 시각으로 덮어써지면 더 좋지만, nil 방지가 핵심.
        newGroup.updatedAt = Timestamp(date: Date())
        
        let memberRef = FirestoreCollection.members(groupId: groupId).document(ownerId)
        let ownerMember = GroupMember.new(from: owner, groupId: groupId, role: .owner)
        
        let codeRef = FirestoreCollection.inviteCode(inviteCode)
        
        // 트랜잭션 쓰기
        do {
            _ = try await db.runTransaction { [self] transaction, errorPointer in
                do {
                    try transaction.setData(from: newGroup, forDocument: groupRef)
                    try transaction.setData(from: ownerMember, forDocument: memberRef)
                    transaction.setData([
                        "groupId": groupId,
                        "createdAt": FieldValue.serverTimestamp(),
                    ], forDocument: codeRef)
                    
                    // User 문서의 groupIds 배열에 추가
                    transaction.updateData([
                        "groupIds": FieldValue.arrayUnion([groupId]),
                        "updatedAt": FieldValue.serverTimestamp(),
                    ], forDocument: FirestoreCollection.user(ownerId))
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
                return nil
            }
        } catch {
            throw GroupError.firestoreFailure(error)
        }
        
        return try await fetchGroup(groupId)
    }
    
    // MARK: - Join
    
    /// 초대 코드로 그룹 참여.
    func joinGroup(inviteCode: String, user: User) async throws -> DamaGroup {
        guard let uid = user.id, !uid.isEmpty else {
            throw GroupError.notAuthenticated
        }
        let code = inviteCode.uppercased()
        
        // 1. 초대 코드 → groupId 조회
        let codeSnapshot: DocumentSnapshot
        do {
            codeSnapshot = try await FirestoreCollection.inviteCode(code).getDocument()
        } catch {
            throw GroupError.firestoreFailure(error)
        }
        guard codeSnapshot.exists,
              let groupId = codeSnapshot.data()?["groupId"] as? String else {
            throw GroupError.inviteCodeNotFound
        }
        
        // 2. 그룹 상태 확인 + 멤버 추가 (트랜잭션)
        let groupRef = FirestoreCollection.group(groupId)
        let memberRef = FirestoreCollection.members(groupId: groupId).document(uid)
        
        do {
            _ = try await db.runTransaction { transaction, errorPointer in
                do {
                    let groupSnap = try transaction.getDocument(groupRef)
                    guard let group = try groupSnap.data(as: DamaGroup?.self) else {
                        errorPointer?.pointee = NSError(
                            domain: "GroupService",
                            code: 404,
                            userInfo: [NSLocalizedDescriptionKey: "group_not_found"]
                        )
                        return nil
                    }
                    
                    if group.isMember(uid) {
                        errorPointer?.pointee = NSError(
                            domain: "GroupService",
                            code: 409,
                            userInfo: [NSLocalizedDescriptionKey: "already_member"]
                        )
                        return nil
                    }
                    
                    if group.isFull {
                        errorPointer?.pointee = NSError(
                            domain: "GroupService",
                            code: 403,
                            userInfo: [NSLocalizedDescriptionKey: "group_full"]
                        )
                        return nil
                    }
                    
                    // 그룹 doc 업데이트
                    transaction.updateData([
                        "memberIds": FieldValue.arrayUnion([uid]),
                        "memberCount": FieldValue.increment(Int64(1)),
                        "updatedAt": FieldValue.serverTimestamp(),
                    ], forDocument: groupRef)
                    
                    // 멤버 서브컬렉션 추가
                    let member = GroupMember.new(from: user, groupId: groupId, role: .member)
                    try transaction.setData(from: member, forDocument: memberRef)
                    
                    // User의 groupIds 갱신
                    transaction.updateData([
                        "groupIds": FieldValue.arrayUnion([groupId]),
                        "updatedAt": FieldValue.serverTimestamp(),
                    ], forDocument: FirestoreCollection.user(uid))
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
                return nil
            }
        } catch let error as NSError {
            // 내부에서 throw한 비즈니스 에러를 GroupError로 변환
            switch error.localizedDescription {
            case "group_not_found": throw GroupError.groupNotFound
            case "already_member": throw GroupError.alreadyMember
            case "group_full": throw GroupError.groupIsFull
            default: throw GroupError.firestoreFailure(error)
            }
        }
        
        return try await fetchGroup(groupId)
    }
    
    // MARK: - Invite Code Generation
    
    /// 충돌 없는 초대 코드 확보. 이미 존재하는 코드라면 재시도.
    private func generateUniqueInviteCode(maxAttempts: Int) async throws -> String {
        for _ in 0..<maxAttempts {
            let code = DamaGroup.generateInviteCode()
            let exists = try await isInviteCodeTaken(code)
            if !exists { return code }
        }
        throw GroupError.codeGenerationFailed
    }
    
    private func isInviteCodeTaken(_ code: String) async throws -> Bool {
        do {
            let snapshot = try await FirestoreCollection.inviteCode(code).getDocument()
            return snapshot.exists
        } catch {
            throw GroupError.firestoreFailure(error)
        }
    }
}
