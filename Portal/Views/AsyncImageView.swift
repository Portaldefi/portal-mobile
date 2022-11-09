//
//  AsyncImageView.swift
//  Portal
//
//  Created by Farid on 02.08.2021.
//

import Foundation
import SwiftUI
import Kingfisher

struct AsyncImageViewModel {
    let imageUrl: URL?
    
    init(url: String) {
        let formattedString = url.replacingOccurrences(of: "http//", with: "https//")
        self.imageUrl = URL(string: formattedString)
    }
}

struct AsyncImageView<Content: View>: View {
    private let placeholder: Content
    private let viewModel: AsyncImageViewModel
 
    init(url: String, @ViewBuilder placeholder: () -> Content) {
        self.viewModel = AsyncImageViewModel(url: url)
        self.placeholder = placeholder()
    }
    
    var body: some View {
        if let imageUrl = viewModel.imageUrl {
            KFImage(imageUrl)
                .cacheOriginalImage()
                .resizable()
                .placeholder {
                    placeholder
                }
        } else {
            placeholder
        }
    }
}
