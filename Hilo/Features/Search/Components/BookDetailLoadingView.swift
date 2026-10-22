//
//  BookDetailLoadingView.swift
//  Hilo
//
//  Created by Cactu on 10-10-26.
//

import SwiftUI

struct BookDetailLoadingView: View {

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            Image("hilo-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .scaleEffect(isAnimating ? 1.05 : 0.95)
                .animation(
                    .easeInOut(duration: 0.9)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }
        }
    }
}

#Preview {
    BookDetailLoadingView()
}
