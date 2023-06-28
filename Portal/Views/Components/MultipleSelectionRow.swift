//
//  MultipleSelectionRow.swift
//  Portal
//
//  Created by farid on 27.06.2023.
//

import SwiftUI

struct MultipleSelectionRow: View {
    let title: String
    let imageUrl: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                CoinImageView(size: 24, url: imageUrl)
                Text(title)
                    .foregroundColor(.white)
                if isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}
