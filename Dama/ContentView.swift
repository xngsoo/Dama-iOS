//
//  ContentView.swift
//  Dama
//
//  Created by SEUNGSOO HAN on 4/20/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.damaCream
                .ignoresSafeArea()
            
            VStack(spacing: DamaSpacing.lg) {
                Text("담아")
                    .font(.damaDisplay)
                    .foregroundStyle(.damaInk)
                
                Text("우리만의 비공개 추억 앨범")
                    .font(.damaBody)
                    .foregroundStyle(.damaInkMuted)
                
                Text("🔥 Firebase Ready")
                    .font(.damaCaption)
                    .foregroundStyle(.damaCoral)
                    .padding(.top, DamaSpacing.md)
            }
        }
    }
}

#Preview("Light") {
    ContentView()
}

#Preview("Dark") {
    ContentView()
        .preferredColorScheme(.dark)
}
