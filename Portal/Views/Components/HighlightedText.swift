//
//  HighlightedText.swift
//  Portal
//
//  Created by farid on 11.07.2023.
//

import SwiftUI
import PortalUI

struct HighlightedText: View {
    let text: String
    let textColor: Color
    let highlight: String?
    let highlightColor: Color
    let font: Font
    let highlightFont: Font
    
    init(text: String, textColor: Color, highlight: String?, highlightColor: Color? = nil, font: Font, highlightFont: Font? = nil) {
        self.text = text
        self.textColor = textColor
        self.highlight = highlight
        
        if let _highlightColor = highlightColor {
            self.highlightColor = _highlightColor
        } else {
            self.highlightColor = Color(red: 255/255, green: 189/255, blue: 20/255, opacity: 1)
        }
        
        self.font = font
        
        if let _highlightFont = highlightFont {
            self.highlightFont = _highlightFont
        } else {
            self.highlightFont = font
        }
    }
    
    var body: some View {
        if let _highlight = highlight, !_highlight.isEmpty, let range = text.range(of: _highlight, options: .caseInsensitive) {
            let prefix = String(text[text.startIndex..<range.lowerBound])
            let target = String(text[range])
            let suffix = String(text[range.upperBound...])
            
            return Text(prefix).font(font).foregroundColor(textColor) + Text(target).font(highlightFont).foregroundColor(highlightColor) + Text(suffix).font(font).foregroundColor(textColor)
        } else {
            return Text(text).font(font).foregroundColor(textColor)
        }
    }
}

struct HighlightedText_Previews: PreviewProvider {
    static var previews: some View {
        HighlightedText(text: "Text", textColor: .gray, highlight: "ext", font: .headline)
    }
}
