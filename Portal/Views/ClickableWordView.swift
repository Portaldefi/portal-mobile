//
//  ClickableWordView.swift
//  Portal
//
//  Created by farid on 11/29/22.
//

import SwiftUI
import PortalUI

struct ClickableWordView: View {
    let index: Int
    let word: String
    
    let onSelectAction: () -> ()
    
    @State var isSelected: Bool = false
    private let isCorrectSelection: Bool
    
    private let correctSelectionColor = Color(red: 0.191, green: 0.858, blue: 0.418)
    private let incorrectSelectionColor = Color(red: 1, green: 0.349, blue: 0.349)
    
    init(index: Int, word: String, isCorrectSelection: Bool = true, onSelect: @escaping () -> ()) {
        self.index = index
        self.word = word
        self.isCorrectSelection = isCorrectSelection
        self.onSelectAction = onSelect
    }
    
    var body: some View {
        HStack(spacing: 2) {
            if isSelected {
                ZStack {
                    Rectangle()
                        .frame(width: 46, height: 46)
                        .foregroundColor(isCorrectSelection ? correctSelectionColor : Color(red: 1, green: 0.349, blue: 0.349))
                        .cornerRadius(12, corners: [.topLeft, .bottomLeft])
                    
                    if isCorrectSelection {
                        Text("\(index)")
                            .font(.Main.fixed(.monoBold, size: 18))
                            .foregroundColor(Palette.grayScale10)
                    }
                }
            } else {
                ZStack {
                    Rectangle()
                        .frame(width: 46, height: 46)
                        .foregroundColor(Palette.grayScale2A)
                        .cornerRadius(12, corners: [.topLeft, .bottomLeft])
                    
                    
                    Rectangle()
                        .frame(width: 43, height: 43)
                        .foregroundColor(Palette.grayScale0A)
                        .cornerRadius(12, corners: [.topLeft, .bottomLeft])
                }
            }
            
            HStack {
                Text(word)
                    .font(.Main.fixed(.monoBold, size: 18))
            }
            .frame(width: 112, height: 46)
            .background(Palette.grayScale2A)
            .cornerRadius(12, corners: [.topRight, .bottomRight])
        }
        .frame(height: 46)
        .onTapGesture {
            isSelected.toggle()
            onSelectAction()
        }
    }
}

struct ClickableWordView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ClickableWordView(index: 1, word: "Test 1", onSelect: {})
                .previewLayout(.sizeThatFits)
            ClickableWordView(index: 2, word: "Test 2", onSelect: {})
                .previewLayout(.sizeThatFits)
            ClickableWordView(index: 2, word: "Test 3", onSelect: {})
                .previewLayout(.sizeThatFits)
            ClickableWordView(index: 3, word: "Test 4", isCorrectSelection: false, onSelect: {})
                .previewLayout(.sizeThatFits)
        }
    }
}
