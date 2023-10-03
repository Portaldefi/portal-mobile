//
//  TransactionDetailsView.swift
// Portal
//
//  Created by farid on 9/29/22.
//

import SwiftUI
import PortalUI
import BitcoinDevKit

struct TransactionDetailsView: View {
    private var viewState: ViewState = Container.viewState()
    @StateObject private var viewModel: TransactionDetailsViewModel
    @Environment(\.presentationMode) private var presentationMode
    
    init(coin: Coin, tx: TransactionRecord) {
        _viewModel = StateObject(wrappedValue: TransactionDetailsViewModel.config(coin: coin, tx: tx))
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
                            
                            TxFeesView(fees: viewModel.feeString, coin: viewModel.coin.code.lowercased(), source: viewModel.source)
                            
                            Divider()
                            
                            if viewModel.source != .lightning {
                                TxIDView(txID: viewModel.txIdString, explorerURL: viewModel.explorerUrl)
                                
                                Divider()
                            } else {
                                HStack(alignment: .firstTextBaseline) {
                                    Text("Payment Preimage")
                                        .font(.Main.fixed(.monoBold, size: 14))
                                        .foregroundColor(Palette.grayScaleAA)
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 8) {
                                        Text(viewModel.transaction.preimage!.turnicated(grouppedBy: 4))
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
                                        Text(viewModel.transaction.nodeId?.turnicated(grouppedBy: 4) ?? "-")
                                            .font(.Main.fixed(.monoRegular, size: 16))
                                            .foregroundColor(Palette.grayScaleF4)
                                    }
                                }
                                .frame(height: 52)
                                
                                Divider()
                            }
                        }
                        
                        NotesView()
                        
                        Divider()
                        
                        LabelsView()
                        
                        Divider()
                    }
                    
                }
                .padding(.horizontal, 16)
            }
            
            if viewModel.editingNotes {
                TextEditorView(
                    title: "Note",
                    placeholder: "Write a note",
                    initialText: viewModel.notes,
                    onCancelAction: {
                        withAnimation {
                            viewModel.editingNotes.toggle()
                        }
                    }, onSaveAction: { notes in
                        viewModel.notes = notes
                        
                        withAnimation {
                            viewModel.editingNotes.toggle()
                        }
                    }
                )
                .cornerRadius(8)
                .offset(y: 5)
                .transition(.move(edge: .bottom))
                .zIndex(1)
            } else if viewModel.editingLabels {
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
                .zIndex(1)
                .ignoresSafeArea(.keyboard)
            }
        }
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
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
            if viewModel.source != .lightning && viewModel.confirmations < 6 && !viewState.isReachable {
                NoInternetConnectionView()
                    .padding(.horizontal, -16)
            }
            
            if viewModel.source != .lightning {
                ConfirmationCounterView(confirmations: viewModel.confirmations)
            }
            
            TxAmountView(
                amount: viewModel.amountString,
                value: viewModel.currencyAmountString,
                coinCode: viewModel.coin.code.lowercased(),
                currencyCode: viewModel.fiatCurrency.code.lowercased()
            )
            
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
        
        TransactionDetailsView(coin: .bitcoin(), tx: TransactionRecord.mocked(confirmed: true))
    }
}

struct TransactionDetailsView_NoInternet: PreviewProvider {
    static var previews: some View {
        let _ = Container.walletManager.register { WalletManager.mocked }
        let _ = Container.adapterManager.register { AdapterManager.mocked }
        let _ = Container.viewState.register { ViewState.mocked(hasConnection: false) }

        TransactionDetailsView(coin: .bitcoin(), tx: TransactionRecord.mocked(confirmed: false))
    }
}
