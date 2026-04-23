//
//  DamaButton.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//

import SwiftUI

enum DamaButtonVariant {
    /// 주요 CTA (Coral filled)
    case primary
    /// 보조 액션 (Outline)
    case secondary
    /// 최소 강조 액션 (텍스트 버튼)
    case text
}

/// Dama 디자인 시스템의 범용 버튼 컴포넌트.
///
/// - Description:
///   앱 전반에서 사용되는 공통 버튼으로, `variant`에 따라 스타일과 역할이 달라진다.
///   로딩 상태, 아이콘, 전체 너비(fullWidth) 등을 지원한다.
///
/// - Variants:
///   - primary: 주요 CTA (강조된 채움 버튼)
///   - secondary: 보조 액션 (outline 스타일)
///   - text: 최소 강조 액션 (텍스트 버튼)
///
/// - Parameters:
///   - title: 버튼에 표시될 텍스트
///   - variant: 버튼 스타일 (기본값: primary)
///   - fullWidth: true일 경우 가로 전체 너비 사용
///   - icon: SF Symbol 이름 (선택)
///   - isLoading: true일 경우 로딩 인디케이터 표시 및 비활성화
///   - action: 버튼 탭 시 실행되는 클로저
///
/// - Example:
/// ```swift
/// DamaButton("포토북 만들기") {
///     start()
/// }
///
/// DamaButton("취소", variant: .secondary) {
///     dismiss()
/// }
///
/// DamaButton("건너뛰기", variant: .text) {
///     skip()
/// }
///
/// DamaButton("로그인 중...", isLoading: true) { }
/// ```
public struct DamaButton: View {
    
    // MARK: - Config
    private let title: String
    private let variant: DamaButtonVariant
    private let fullWidth: Bool
    private let icon: String?
    private let isLoading: Bool
    private let action: () -> Void
    
    // MARK: - Init
    init(
        _ title: String,
        variant: DamaButtonVariant = .primary,
        fullWidth: Bool = false,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.fullWidth = fullWidth
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }
    
    // MARK: - Body
    public var body: some View {
        Button(action: action) {
            HStack(spacing: DamaSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(loadingTint)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                
                Text(title)
                    .font(.damaLabel)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
        }
        .buttonStyle(DamaButtonStyle(variant: variant, disabled: isLoading))
        .disabled(isLoading)
    }
    
    private var loadingTint: Color {
        switch variant {
        case .primary:
            return DamaButtonStyle.primaryFixedCream
        case .secondary, .text:
            return .damaInk
        }
    }
}

// MARK: - ButtonStyle (press animation + variant styling)

private struct DamaButtonStyle: ButtonStyle {
    
    let variant: DamaButtonVariant
    let disabled: Bool
    
    /// Primary 버튼 텍스트 색 — 모드 불변(라이트/다크 동일).
    /// Coral 배경이 다크 모드에서도 코랄을 유지하므로 텍스트도 크림 고정.
    static let primaryFixedCream = Color(red: 251/255, green: 244/255, blue: 229/255)
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, DamaSpacing.lg)
            .padding(.vertical, DamaSpacing.md)
            .foregroundColor(foregroundColor)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .clipShape(Capsule())
            .contentShape(Capsule())
            .overlay(borderOverlay)
            .opacity(disabled ? 0.5 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .primary: return Self.primaryFixedCream
        case .secondary: return .damaInk
        case .text: return .damaCoral
        }
    }
    
    private func backgroundColor(isPressed: Bool) -> Color {
        switch variant {
        case .primary: return isPressed ? .damaCoralDeep : .damaCoral
        case .secondary: return isPressed ? .damaInk.opacity(0.06) : .clear
        case .text: return .clear
        }
    }
    
    @ViewBuilder
    private var borderOverlay: some View {
        switch variant {
        case .secondary:
            Capsule()
                .stroke(Color.damaInk.opacity(0.15), lineWidth: 0.5)
        default:
            EmptyView()
        }
    }
}

// MARK: - Preview

#Preview("Light") {
    previewContent()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    previewContent()
        .preferredColorScheme(.dark)
}

private func previewContent() -> some View {
    VStack(spacing: DamaSpacing.md) {
        DamaButton("포토북 만들기", fullWidth: true) { }
        DamaButton("Apple로 계속하기", fullWidth: true, icon: "apple.logo") { }
        DamaButton("카카오로 계속하기", variant: .secondary, fullWidth: true) { }
        DamaButton("로그인 중...", fullWidth: true, isLoading: true) { }
        DamaButton("건너뛰기", variant: .text) { }
    }
    .padding(DamaSpacing.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.damaCream)
}
