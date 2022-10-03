//
//  TextEditorView.swift
//  BDKDemoApp
//
//  Created by farid on 10/3/22.
//

import SwiftUI
import PortalUI

struct TextEditorView: View {
    @FocusState private var firstResponder: Bool
    @StateObject private var viewModel: TextEditorViewModel
    
    init(
        title: String,
        placeholder: String,
        initialText: String,
        onCancelAction: @escaping () -> (),
        onSaveAction: @escaping (String) -> ()
    ) {
        _viewModel = StateObject(wrappedValue:
            TextEditorViewModel(
                title: title,
                placeholder: placeholder,
                initialText: initialText,
                onCancelAction: onCancelAction,
                onSaveAction: onSaveAction
            )
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(viewModel.title)
                    .font(.Main.fixed(.monoBold, size: 16))
                    .foregroundColor(Palette.grayScaleF4)
                
                HStack {
                    PButton(config: .onlyLabel("Cancel"), style: .free, size: .small, color: Color(red: 1, green: 0.349, blue: 0.349), applyGradient: false, enabled: true) {
                        viewModel.onCancelAcion()
                    }
                    .frame(width: 58)
                    
                    Spacer()
                    
                    PButton(config: .onlyLabel("Save"), style: .free, size: .small, applyGradient: true, enabled: viewModel.saveButtonEnabled) {
                        viewModel.onSaveAcion(viewModel.text)
                    }
                    .frame(width: 39)
                }
                .padding(.vertical, 20)
            }
            .frame(height: 62)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.text)
                    .lineLimit(5)
                    .focused($firstResponder)
                    .font(.Main.fixed(.monoBold, size: 16))
                    .foregroundColor(Palette.grayScaleF4)
                    .padding(8)

                if viewModel.text.isEmpty {
                    Text(viewModel.placeHolder)
                        .font(.Main.fixed(.monoBold, size: 14))
                        .foregroundColor(Palette.grayScale6A)
                        .padding(16)
                }
            }
            .background(Color(red: 28/255, green: 28/255, blue: 30/255))
            .cornerRadius(8)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 16)
        .background(Palette.grayScale2A)
        .frame(height: 216)
        .onAppear {
            firstResponder.toggle()
        }
    }
}

struct TextEditorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TextEditorView(
                title: "Note",
                placeholder: "Write a note",
                initialText: String(),
                onCancelAction: {},
                onSaveAction: { _ in }
            )
            
            TextEditorView(
                title: "Note",
                placeholder: "Write a note",
                initialText: "Design Services. Payment 1/5 and some longer text to test the expandability of the component",
                onCancelAction: {},
                onSaveAction: { _ in }
            )
        }
        .previewLayout(.sizeThatFits)
    }
}
