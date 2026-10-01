//
//  BasicStatisticCard.swift
//  Hilo
//
//  Created by Cactu on 10-09-26.
//

import SwiftUI

struct BasicStatisticCard: View {
    let value: Int
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundStyle(AppColors.accent)
                .fontWeight(.bold)
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.callout)
                .foregroundStyle(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}
