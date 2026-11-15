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

    private var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .autoupdatingCurrent
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(AppColors.accent)
                .fontWeight(.bold)
                .frame(width: 32, height: 32)
                .background(AppColors.accentSurface, in: RoundedRectangle(cornerRadius: 10))
            Text(formattedValue)
                .foregroundStyle(AppColors.accent)
                .font(.title2)
                .fontWeight(.bold)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 30, alignment: .top)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 98)
    }
}
