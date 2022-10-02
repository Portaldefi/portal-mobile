//
//  TransactionDetailsView.swift
//  BDKDemoApp
//
//  Created by farid on 9/29/22.
//

import SwiftUI
import PortalUI
import BitcoinDevKit

struct TransactionDetailsView: View {
    @ObservedObject private var viewModel: TransactionDetailsViewModel
    @Environment(\.presentationMode) private var presentationMode
    
    init(coin: Coin, tx: BitcoinDevKit.Transaction) {
        viewModel = TransactionDetailsViewModel.config(coin: coin, tx: tx)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                NavigationView()
                
                TxSummaryView()
                
                Divider().frame(height: 1)

                VStack(spacing: 0) {
                    TxRecipientView(recipient: viewModel.recipientString)
                    
                    Divider()
                    
                    TxFeesView(fees: viewModel.feeString)
                    
                    Divider()
                    
                    TxIDView(txID: viewModel.txIdString, explorerURL: viewModel.explorerUrl)
                    
                    Divider()
                    
                    NotesButton()
                    
                    Divider()
                    
                    LabelsButton()
                    
                    Divider()
                }
                
            }
            .padding(.horizontal, 16)
        }
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
        .navigationBarHidden(true)
    }
    
    private func NotesButton() -> some View {
        HStack {
            PButton(config: .labelAndIconLeft(label: "Add Note", icon: Asset.pencilIcon), style: .free,size: .small, applyGradient: true, enabled: true) {
                
            }
            .frame(width: 120)
            
            Spacer()
        }
        .frame(height: 62)
    }
    
    private func LabelsButton() -> some View {
        HStack {
            PButton(config: .labelAndIconLeft(label: "Add Label", icon: Asset.tagIcon), style: .free, size: .small, applyGradient: true, enabled: true) {
                
            }
            .frame(width: 120)
            
            Spacer()
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
    
    private func NavigationView() -> some View {
        ZStack {
            HStack {
                PButton(config: .onlyIcon(Asset.xIcon), style: .free, size: .medium, applyGradient: true, enabled: true) {
                    withAnimation {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .frame(width: 30, height: 30)
                
                Spacer()
                
                PButton(config: .onlyLabel("Share"), style: .free, size: .small, applyGradient: true, enabled: true) {
                    withAnimation {
                        presentationMode.wrappedValue.dismiss()
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
}

extension BitcoinDevKit.Transaction {
    static var mockedConfirmed: BitcoinDevKit.Transaction {
        let details = TransactionDetails(
            fee: 141,
            received: 55000,
            sent: 0,
            txid: "088719f8db335b69c1e1a57b06d6925c941e99bf55607394e0902283a70fd44e"
        )
        let blockTime = BlockTime(height: 2345912, timestamp: 1662707961)
        
        return BitcoinDevKit.Transaction.confirmed(details: details, confirmation: blockTime)
    }
}

struct TransactionDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionDetailsView(coin: .bitcoin(), tx: BitcoinDevKit.Transaction.mockedConfirmed)
    }
}
