//
//  DamaButton.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//
//    사용 예:
//    DamaButton("로그인", variant: .primary, fullWidth: true) { login() }
//    DamaButton("취소", variant: .secondary) { dismiss() }
//    DamaButton("건너뛰기", variant: .text) { skip() }

import SwiftUI

enum DamaButtonVariant {
    case primary    // Coral filled — 주요 CTA
    case secondary  // Outline — 보조 액션
    case text       // Coral 텍스트만 — 최소 강조
}

struct DamaButton: View {
    
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
    var body: some View {
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
        .buttonStyle(_DamaButtonStyle(variant: variant, disabled: isLoading))
        .disabled(isLoading)
    }
    
    private var loadingTint: Color {
        variant == .primary ? _DamaButtonStyle.primaryFixedCream : .damaInk
    }
}

// MARK: - ButtonStyle (press animation + variant styling)

private struct _DamaButtonStyle: ButtonStyle {
    
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
        if variant == .secondary {
            Capsule()
                .stroke(Color.damaInk.opacity(0.15), lineWidth: 0.5)
        }
    }
}

// MARK: - Preview

#Preview("Light") {
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

#Preview("Dark") {
    VStack(spacing: DamaSpacing.md) {
        DamaButton("포토북 만들기", fullWidth: true) { }
        DamaButton("취소", variant: .secondary, fullWidth: true) { }
        DamaButton("건너뛰기", variant: .text) { }
    }
    .padding(DamaSpacing.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.damaCream)
    .preferredColorScheme(.dark)
}
