//
//  PhotoUploadSheet.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/21/26.
//
//  업로드 중 단계별 진행 상태를 보여주는 비차단 시트.

import SwiftUI

struct PhotoUploadSheet: View {
    
    @ObservedObject var viewModel: PhotoUploadViewModel
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.damaCream.ignoresSafeArea()
            
            VStack(spacing: DamaSpacing.xl) {
                Spacer()
                
                DamaPhotoTile(rotation: 0) {
                    iconContent
                        .frame(width: 120, height: 120)
                }
                
                VStack(spacing: DamaSpacing.sm) {
                    Text(title)
                        .font(.damaSubheadline)
                        .foregroundColor(.damaInk)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.damaCaption)
                        .foregroundColor(.damaInkMuted)
                        .multilineTextAlignment(.center)
                }
                
                if case let .uploading(current, total) = viewModel.state {
                    progressBar(current: current, total: total)
                        .padding(.horizontal, DamaSpacing.xl)
                }
                
                Spacer()
                
                if case .completed = viewModel.state {
                    DamaButton("확인", fullWidth: true, action: onDismiss)
                        .padding(.horizontal, DamaSpacing.xl)
                        .padding(.bottom, DamaSpacing.xl)
                }
            }
        }
        .interactiveDismissDisabled(isUploading)
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var iconContent: some View {
        switch viewModel.state {
        case .idle, .uploading:
            ZStack {
                Color.damaCreamWarm
                ProgressView()
                    .scaleEffect(1.4)
                    .tint(.damaCoral)
            }
        case .completed(let successful, let failed):
            ZStack {
                Color.damaCoral.opacity(failed > 0 ? 0.3 : 1)
                Image(systemName: failed == 0 ? "checkmark" : "exclamationmark")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(successful > 0 ? _PrimaryCream : .damaInk)
            }
        }
    }
    
    private var title: String {
        switch viewModel.state {
        case .idle:
            return "준비 중…"
        case .uploading(let current, let total):
            return "사진을 담고 있어요\n(\(current) / \(total))"
        case .completed(let successful, let failed):
            if failed == 0 {
                return "\(successful)장 담았어요"
            } else if successful == 0 {
                return "업로드에 실패했어요"
            } else {
                return "\(successful)장 성공, \(failed)장 실패"
            }
        }
    }
    
    private var subtitle: String {
        switch viewModel.state {
        case .idle:
            return " "
        case .uploading:
            return "잠시만 기다려주세요"
        case .completed:
            return viewModel.errorMessage ?? "우리만의 공간에 새로운 기억이 쌓였어요"
        }
    }
    
    private var isUploading: Bool {
        if case .uploading = viewModel.state { return true }
        return false
    }
    
    private func progressBar(current: Int, total: Int) -> some View {
        let fraction = total > 0 ? Double(current) / Double(total) : 0
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.damaBorder)
                Capsule()
                    .fill(Color.damaCoral)
                    .frame(width: geo.size.width * fraction)
                    .animation(.easeOut(duration: 0.3), value: fraction)
            }
        }
        .frame(height: 6)
    }
    
    private let _PrimaryCream = Color(red: 251/255, green: 244/255, blue: 229/255)
}

#Preview("Uploading") {
    let vm = PhotoUploadViewModel()
    PhotoUploadSheet(viewModel: vm, onDismiss: { })
        .onAppear {
            // Preview용 강제 주입은 비공개 set 때문에 불가.
            // 실제 동작은 GroupDetailView에서 확인.
        }
}
