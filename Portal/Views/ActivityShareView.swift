//
//  ActivityShareView.swift
// Portal
//
//  Created by farid on 10/20/22.
//

import Foundation
import SwiftUI

struct ActivityShareView: UIViewControllerRepresentable {
    let text: String
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityShareView>) -> UIActivityViewController {
        return UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityShareView>) {}
}

