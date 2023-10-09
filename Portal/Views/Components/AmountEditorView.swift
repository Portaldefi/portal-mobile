//
//  AmountEditorView.swift
// Portal
//
//  Created by farid on 10/18/22.
//

import SwiftUI
import PortalUI
import Combine

//@Observable class AmontEditorViewModel {
//    let title: String
//        
//    var saveButtonEnabled = false
//    @ObservationIgnored var exchanger: Exchanger
//    
//    private let initialAmount: String
//    
//    @ObservationIgnored private var subscriptions = Set<AnyCancellable>()
//    
//    init(title: String, exchanger: Exchanger) {
//        self.title = title
//        self.exchanger = exchanger
//        self.initialAmount = exchanger.amount.string
//        
//        self.exchanger.amount.$string.flatMap{Just(!$0.isEmpty && $0 != self.initialAmount)}.sink { newValue in
//            self.saveButtonEnabled = newValue
//        }
//        .store(in: &subscriptions)
//    }
//    
//    func onCancel() {
//        exchanger.amount.string = initialAmount
//    }
//}


class AmontEditorViewModel: ObservableObject {
    let title: String
        
    @Published var saveButtonEnabled = false
    @Published var exchanger: Exchanger
    
    private let initialAmount: String
    
    init(title: String, exchanger: Exchanger) {
        self.title = title
        self.exchanger = exchanger
        self.initialAmount = exchanger.amount.string
        self.exchanger.amount.$string.flatMap{Just(!$0.isEmpty && $0 != self.initialAmount)}.assign(to: &$saveButtonEnabled)
    }
    
    func onCancel() {
        exchanger.amount.string = initialAmount
    }
}

struct AmountEditorView: View {
    @FocusState private var firstResponder: Bool
    @StateObject private var viewModel: AmontEditorViewModel
    
    let onCancelAcion: () -> ()
    let onSaveAcion: () -> ()
    
    init(
        title: String,
        exchanger: Exchanger,
        onCancelAction: @escaping () -> (),
        onSaveAction: @escaping () -> ()
    ) {
        let vm = AmontEditorViewModel(title: title, exchanger: exchanger)
        self._viewModel = StateObject(wrappedValue: vm)
        
        self.onCancelAcion = onCancelAction
        self.onSaveAcion = onSaveAction
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(viewModel.title)
                    .font(.Main.fixed(.monoBold, size: 16))
                    .foregroundColor(Palette.grayScaleF4)
                
                HStack {
                    PButton(config: .onlyLabel("Cancel"), style: .free, size: .small, color: Color(red: 1, green: 0.349, blue: 0.349), applyGradient: false, enabled: true) {
                        viewModel.onCancel()
                        onCancelAcion()
                    }
                    .frame(width: 58)
                    
                    Spacer()
                    
                    PButton(config: .onlyLabel("Save"), style: .free, size: .small, applyGradient: true, enabled: viewModel.saveButtonEnabled) {
                        onSaveAcion()
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
                
            }, onSaveAction: {
                
            })
        .previewLayout(.sizeThatFits)
    }
}
