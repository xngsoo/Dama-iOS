//
//  SplashView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//
//  앱 진입 시 ~1.2초 동안 로고를 보여주고 Login으로 전환.
    
import SwiftUI

struct SplashView: View {

    let onComplete: () -> Void
    
    @State private var logoOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.damaCream.ignoresSafeArea()
            
            VStack(spacing: DamaSpacing.sm) {
                Text("담아")
                    .font(.damaDisplay)
                    .foregroundColor(.damaInk)
                    .opacity(logoOpacity)
                
                Text("우리만의 작은 앨범")
                    .font(.damaCaption)
                    .foregroundColor(.damaInkMuted)
                    .opacity(taglineOpacity)
                    .padding(.top, DamaSpacing.xs)
            }
        }
        .task {
            withAnimation(.easeOut(duration: 0.6)) {
                logoOpacity = 1
            }
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.easeOut(duration: 0.5)) {
                taglineOpacity = 1
            }
            try? await Task.sleep(for: .milliseconds(900))
            onComplete()
        }
    }
}

#Preview("Light") {
    SplashView(onComplete: { })
}

#Preview("Dark") {
    SplashView(onComplete: { })
        .preferredColorScheme(.dark)
}
