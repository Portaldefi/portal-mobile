//
//  CircleProgressView.swift
//  Portal
//
//  Created by farid on 27.06.2023.
//

import SwiftUI
import PortalUI

struct CircleProgressView: View {
    let totalPages: Int
    let currentIndex: Int
    
    var body: some View {
        HStack {
            ForEach(0..<totalPages, id:\.self) { index in
                ZStack {
                    Circle()
                        .stroke(style: .init(lineWidth: 2))
                        .foregroundColor(Palette.grayScale8A)
                    if index <= currentIndex - 1 {
                        Circle()
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
    }
}

struct CircleProgressView_Previews: PreviewProvider {
    static var previews: some View {
        CircleProgressView(totalPages: 4, currentIndex: 0)
    }
}
