//
//  RoundedCornerShape.swift
//  Portal
//
//  Created by farid on 11/29/22.
//

import SwiftUI

struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct RoundedCornerShape_Previews: PreviewProvider {
    static var previews: some View {
        RoundedCornerShape(radius: 12, corners: [.topLeft, .bottomLeft])
            .frame(width: 150, height: 80)
            .padding()
    }
}
