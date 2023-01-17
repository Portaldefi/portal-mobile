//
//  AmountEditorView.swift
// Portal
//
//  Created by farid on 10/18/22.
//

import SwiftUI
import PortalUI
import Combine

class AmontEditorViewModel: ObservableObject {
    let title: String
    let onCancelAcion: () -> ()
    let onSaveAcion: (String) -> ()
    
    @Published var saveButtonEnabled = false
    @Published var exchanger: Exchanger
    let initialAmount: String
    
    init(
        title: String,
        exchanger: Exchanger,
        onCancelAction: @escaping () -> (),
        onSaveAction: @escaping (String) -> ()
    ) {
        self.title = title
        self.onCancelAcion = onCancelAction
        self.onSaveAcion = onSaveAction
        self.exchanger = exchanger
        
        self.initialAmount = exchanger.baseAmountString
        
        self.exchanger.amount.$string.flatMap {
            Just($0 != self.initialAmount)
        }
        .assign(to: &$saveButtonEnabled)
    }
}

struct AmountEditorView: View {
    @FocusState private var firstResponder: Bool
    @StateObject private var viewModel: AmontEditorViewModel
    
    init(
        title: String,
        exchanger: Exchanger,
        onCancelAction: @escaping () -> (),
        onSaveAction: @escaping (String) -> ()
    ) {
        _viewModel = StateObject(
            wrappedValue: AmontEditorViewModel(
                title: title,
                exchanger: exchanger,
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
                        viewModel.onSaveAcion(viewModel.exchanger.baseAmountString)
                    }
                    .frame(width: 39)
                }
                .padding(.vertical, 20)
            }
            .frame(height: 62)
            
            AmountView(exchanger: viewModel.exchanger, isValid: true, validate: false)
                .background(Color(red: 28/255, green: 28/255, blue: 30/255))
                .cornerRadius(8)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 16)
        .background(Palette.grayScale2A)
        .frame(height: 168)
        .onAppear {
            firstResponder.toggle()
        }
    }
}

struct AmountEditorView_Previews: PreviewProvider {
    static var previews: some View {
        AmountEditorView(
            title: "Add Amount",
            exchanger: Exchanger.mocked(),
            onCancelAction: {
                
            }, onSaveAction: { amount in
                
            })
        .previewLayout(.sizeThatFits)
    }
}
