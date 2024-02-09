//
//  TransactionView.swift
// Portal
//
//  Created by farid on 9/29/22.
//

import SwiftUI
import PortalUI
import BitcoinDevKit

struct TransactionView: View {
    private var viewState: ViewState = Container.viewState()
    @StateObject private var viewModel: TransactionViewModel
    @Environment(\.presentationMode) private var presentationMode
    
    init(coin: Coin, tx: TransactionRecord) {
        _viewModel = StateObject(wrappedValue: TransactionViewModel.config(coin: coin, tx: tx))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    NavigationView()
                    
                    TxSummaryView()
                    
                    Divider().frame(height: 1)

                    VStack(spacing: 0) {
                        Group {
                            if let recipient = viewModel.recipientString {
                                TxAddressView(title: "Recipient", address: recipient.turnicated(grouppedBy: 4))
                            }
                            
                            Divider()
                            
                            if let sender = viewModel.senderString {
                                TxAddressView(title: "Sender", address: sender.turnicated(grouppedBy: 4))
                            }
                            
                            Divider()
                            
                            TxFeesView(fees: viewModel.feeString, source: viewModel.source)
                            
                            Divider()
                            
                            switch viewModel.source {
                            case .bitcoin, .ethereum, .erc20:
                                TxIDView(txID: viewModel.txIdString, explorerURL: viewModel.explorerUrl)
                                
                                Divider()
                            case .lightning:
                                switch viewModel.transaction {
                                case let record as LNTransactionRecord:
                                    HStack(alignment: .firstTextBaseline) {
                                        Text("Payment Preimage")
                                            .font(.Main.fixed(.monoBold, size: 14))
                                            .foregroundColor(Palette.grayScaleAA)
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 8) {
                                            Text(record.preimage?.turnicated(grouppedBy: 4) ?? "-")
                                                .font(.Main.fixed(.monoRegular, size: 16))
                                                .foregroundColor(Palette.grayScaleF4)
                                        }
                                    }
                                    .frame(height: 52)
                                    
                                    Divider()
                                    
                                    HStack(alignment: .firstTextBaseline) {
                                        Text("Node ID")
                                            .font(.Main.fixed(.monoBold, size: 14))
                                            .foregroundColor(Palette.grayScaleAA)
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 8) {
                                            Text(record.nodeId?.turnicated(grouppedBy: 4) ?? "-")
                                                .font(.Main.fixed(.monoRegular, size: 16))
                                                .foregroundColor(Palette.grayScaleF4)
                                        }
                                    }
                                    .frame(height: 52)
                                    
                                    Divider()
                                default:
                                    EmptyView()
                                }
                            case .swap(let base, let quote):
                                EmptyView()
                            }
                        }
                        
                        switch (viewModel.notes.isEmpty, viewModel.labels.isEmpty) {
                        case (false, true):
                            NotesView()
                            
                            Divider()
                            
                            LabelsView()
                        case (true, false):
                            LabelsView()
                            
                            Divider()
                            
                            NotesView()
                        default:
                            NotesView()
                            
                            Divider()
                            
                            LabelsView()
                        }
                        
                        Divider()
                    }
                    
                }
                .padding(.horizontal, 16)
            }
            
            if viewModel.editingLabels {
                LabelsManagerView(
                    viewModel: .init(selectedLabels: viewModel.labels),
                    onSaveAcion: {
                        viewModel.labels = $0
                        withAnimation {
                            viewModel.editingLabels.toggle()
                        }
                    }
                )
                .transition(.move(edge: .bottom))
                .animation(.easeInOut(duration: 0.55), value: viewModel.editingLabels)
                .zIndex(1)
                .ignoresSafeArea(.keyboard)
            }
        }
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
        .popup(isPresented: $viewModel.editingNotes) {
            TextEditorView(
                title: "Note",
                placeholder: "Write a note",
                initialText: viewModel.notes,
                onCancelAction: {
                    viewModel.editingNotes.toggle()
                }, onSaveAction: { notes in
                    viewModel.notes = notes
                    viewModel.editingNotes.toggle()
                }
            )
            .cornerRadius(8, corners: [.topLeft, .topRight])
            .padding(.bottom, 32)
        } customize: {
            $0
                .type(.toast)
                .position(.bottom)
                .animation(.easeInOut(duration: 0.55))
                .closeOnTap(false)
                .closeOnTapOutside(false)
                .backgroundColor(.black.opacity(0.5))
        }
    }
    
    private func NavigationView() -> some View {
        ZStack {
            HStack {
                PButton(config: .onlyIcon(Asset.xIcon), style: .free, size: .medium, applyGradient: true, enabled: true) {
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(width: 30, height: 30)
                
                Spacer()
                
                PButton(config: .onlyLabel("Share"), style: .free, size: .small, applyGradient: true, enabled: true) {
                    withAnimation {
                        
                    }
                }
                .frame(width: 48, height: 16)
            }
            
            Text(viewModel.title)
                .frame(width: 300, height: 62)
                .font(.Main.fixed(.monoBold, size: 16))
            
        }
        .frame(height: 62)
    }
    
    private func TxSummaryView() -> some View {
        VStack(spacing: 24) {
            switch viewModel.source {
            case .bitcoin, .ethereum, .erc20:
                if viewModel.confirmations < 6 && !viewState.isReachable {
                    NoInternetConnectionView()
                        .padding(.horizontal, -16)

                }
                ConfirmationCounterView(confirmations: viewModel.confirmations)
                
                TxAmountView(
                    amount: viewModel.amountString,
                    value: viewModel.currencyAmountString,
                    coinCode: viewModel.coin.code.lowercased(),
                    currencyCode: viewModel.fiatCurrency.code.lowercased()
                )
            case .lightning:
                TxAmountView(
                    amount: viewModel.amountString,
                    value: viewModel.currencyAmountString,
                    coinCode: viewModel.coin.code.lowercased(),
                    currencyCode: viewModel.fiatCurrency.code.lowercased()
                )
            case .swap:
                if viewModel.confirmations < 6 && !viewState.isReachable {
                    NoInternetConnectionView()
                        .padding(.horizontal, -16)
                }
                
                switch viewModel.transaction {
                case let record as SwapTransactionRecord:
                    VStack(alignment: .center, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("+ ")
                                .font(.Main.fixed(.monoBold, size: 32))
                                .foregroundColor(Palette.grayScale6A)
                            + Text(record.quoteQuantity.double.toString(decimal: 8))
                                .font(.Main.fixed(.monoBold, size: 32))
                                .foregroundColor(Palette.grayScaleEA)
                            
                            Text(record.quote.code.lowercased())
                                .font(.Main.fixed(.monoRegular, size: 18))
                                .foregroundColor(Palette.grayScale6A)
                        }
                        
                        Asset.switchIcon.resizable().frame(width: 22, height: 22).rotationEffect(.degrees(90))
                        
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("- ")
                                .font(.Main.fixed(.monoBold, size: 32))
                                .foregroundColor(Palette.grayScale6A)
                            + Text(record.baseQuantity.double.toString(decimal: 8))
                                .font(.Main.fixed(.monoBold, size: 32))
                                .foregroundColor(Palette.grayScaleEA)
                            
                            Text(record.base.code.lowercased())
                                .font(.Main.fixed(.monoRegular, size: 18))
                                .foregroundColor(Palette.grayScale6A)
                        }
                    }
                default:
                    EmptyView()
                }
            }
            
            Text(viewModel.dateString)
                .font(.Main.fixed(.monoMedium, size: 16))
                .foregroundColor(Palette.grayScaleAA)
        }
        .padding(.bottom, 24)
    }
    
    private func NotesView() -> some View {
        Group {
            if viewModel.notes.isEmpty {
                Button {
                    withAnimation {
                        viewModel.editingNotes.toggle()
                    }
                } label: {
                    HStack {
                        PButton(config: .labelAndIconLeft(label: "Add Note", icon: Asset.pencilIcon), style: .free,size: .small, applyGradient: true, enabled: true) {
                            withAnimation {
                                viewModel.editingNotes.toggle()
                            }
                        }
                        .frame(width: 120)
                        
                        Spacer()
                    }
                    .frame(height: 62)
                }
            } else {
                Button {
                    withAnimation {
                        viewModel.editingNotes.toggle()
                    }
                } label: {
                    EditableTextFieldView(description: "Notes", text: viewModel.notes)
                }
            }
        }
    }
    
    private func LabelsView() -> some View {
        Group {
            if viewModel.labels.isEmpty {
                Button {
                    withAnimation {
                        viewModel.editingLabels.toggle()
                    }
                } label: {
                    HStack {
                        PButton(config: .labelAndIconLeft(label: "Add Label", icon: Asset.tagIcon), style: .free, size: .small, applyGradient: true, enabled: true) {
                            withAnimation {
                                viewModel.editingLabels.toggle()
                            }
                        }
                        .frame(width: 120)
                        
                        Spacer()
                    }
                    .frame(height: 62)
                }
            } else {
                Button {
                    withAnimation {
                        viewModel.editingLabels.toggle()
                    }
                } label: {
                    TxLabelsView(labels: viewModel.labels)
                }
            }
        }
    }
}

import Factory

struct TransactionDetailsView_Confirmed_Has_Connection: PreviewProvider {
    static var previews: some View {
        let _ = Container.walletManager.register { WalletManager.mocked }
        let _ = Container.adapterManager.register { AdapterManager.mocked }
        let _ = Container.viewState.register { ViewState.mocked(hasConnection: true) }
        
        TransactionView(coin: .bitcoin(), tx: TransactionRecord.mocked(confirmed: true))
    }
}

struct TransactionDetailsView_NoInternet: PreviewProvider {
    static var previews: some View {
        let _ = Container.walletManager.register { WalletManager.mocked }
        let _ = Container.adapterManager.register { AdapterManager.mocked }
        let _ = Container.viewState.register { ViewState.mocked(hasConnection: false) }

        TransactionView(coin: .bitcoin(), tx: TransactionRecord.mocked(confirmed: false))
    }
}
