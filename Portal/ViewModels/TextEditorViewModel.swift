//
//  TextEditorViewModel.swift
// Portal
//
//  Created by farid on 10/3/22.
//

import Foundation
import Combine

class TextEditorViewModel: ObservableObject {
    let title: String
    let placeHolder: String
    let initialText: String
        
    let onCancelAcion: () -> ()
    let onSaveAcion: (String) -> ()
    
    @Published var text = TextLimiter(initialText: "Write a note", limit: 140)
    @Published var saveButtonEnabled = false
    
    init(title: String,
         placeholder: String,
         initialText: String,
         onCancelAction: @escaping () -> (),
         onSaveAction: @escaping (String) -> ()
    ) {
        self.title = title
        self.placeHolder = placeholder
        self.initialText = initialText
        self.onCancelAcion = onCancelAction
        self.onSaveAcion = onSaveAction
        
        text.string = initialText
        
        text.updated
            .flatMap { Just($0 != initialText) }
            .assign(to: &$saveButtonEnabled)
    }
}

