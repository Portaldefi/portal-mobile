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
    @StateObject private var viewModel: TransactionDetailsViewModel
    @Environment(\.presentationMode) private var presentationMode
    
    init(coin: Coin, tx: BitcoinDevKit.TransactionDetails) {
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
                        if let recipient = viewModel.recipientString {
                            TxRecipientView(recipient: recipient)
                        }
                        
                        Divider()
                        
                        TxFeesView(fees: viewModel.feeString)
                        
                        Divider()
                        
                        TxIDView(txID: viewModel.txIdString, explorerURL: viewModel.explorerUrl)
                        
                        Divider()
                        
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
        .navigationBarHidden(true)
    }
    
    private func NavigationView() -> some View {
        ZStack {
            HStack {
                PButton(config: .onlyIcon(Asset.xIcon), style: .free, size: .medium, applyGradient: true, enabled: true) {
                    withAnimation {
                        if viewModel.viewState.goToSend {
                            viewModel.viewState.goToSend = false
                        } else if viewModel.viewState.goToSendFromDetails {
                            viewModel.viewState.goToSendFromDetails = false
                        } else if viewModel.viewState.showQRCodeScannerFromTabBar {
                            viewModel.viewState.showQRCodeScannerFromTabBar = false
                        } else if viewModel.viewState.showInContextScanner {
                            viewModel.viewState.showInContextScanner = false
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
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
            ConfirmationCounterView(confirmations: viewModel.confirmations)
            
            TxAmountView(amount: viewModel.amountString, value: viewModel.currencyAmountString)
            
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

struct TransactionDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionDetailsView(coin: .bitcoin(), tx: BitcoinDevKit.TransactionDetails.mockedConfirmed)
    }
}
