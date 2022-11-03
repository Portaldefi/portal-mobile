//
//  SingleTxView.swift
//  BDKDemoApp
//
//  Created by farid on 7/21/22.
//

import SwiftUI
import BitcoinDevKit
import PortalUI

struct SingleTxView: View {
    @ObservedObject var viewModel: SingleTxViewModel
    
    init(transaction: BitcoinDevKit.TransactionDetails) {
        self._viewModel = ObservedObject(initialValue: SingleTxViewModel(tx: transaction))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    if viewModel.tx.sent > 0 {
                        Asset.txSentIcon.cornerRadius(16)
                            .offset(y: -6)
                    } else {
                        Asset.txReceivedIcon.cornerRadius(16)
                            .offset(y: -6)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text(viewModel.tx.type.description)
                            .font(.Main.fixed(.monoMedium, size: 16))
                            .foregroundColor(Palette.grayScaleCA)
                        if let confirmatioDate = viewModel.tx.confirmationTimeString {
                            Text(confirmatioDate)
                                .font(.Main.fixed(.monoRegular, size: 14))
                                .lineLimit(1)
                                .foregroundColor(Palette.grayScale6A)
                        } else {
                            Text("Confirming...")
                                .font(.Main.fixed(.monoRegular, size: 14))
                                .lineLimit(1)
                                .foregroundColor(Color(red: 1, green: 0.742, blue: 0.079))
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        VStack(alignment: .trailing, spacing: 0) {
                            HStack {
                                Text("\(viewModel.tx.type == .recieved ? "+" : "-")")
                                    .font(.Main.fixed(.monoMedium, size: 16))
                                    .foregroundColor(viewModel.tx.type == .recieved ? Color(red: 0.191, green: 0.858, blue: 0.418) : Palette.grayScaleEA)
                                Text(viewModel.tx.value)
                                    .font(.Main.fixed(.monoMedium, size: 16))
                                    .foregroundColor(viewModel.tx.type == .recieved ? Color(red: 0.191, green: 0.858, blue: 0.418) : Palette.grayScaleEA)
                            }
                            HStack {
                                Text("\(viewModel.tx.type == .recieved ? "+" : "-")")
                                    .font(.Main.fixed(.monoBold, size: 16))
                                    .foregroundColor(Palette.grayScale6A)
                                Text("4.55")
                                    .font(.Main.fixed(.monoRegular, size: 16))
                                    .foregroundColor(Palette.grayScale6A)
                                    .offset(x: 1)
                            }
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("btc")
                                    .font(.Main.fixed(.monoMedium, size: 12))
                                    .foregroundColor(Palette.grayScale6A)
                                    .offset(y: -1)
                                Spacer()
                            }
                            .frame(width: 30)
                            Text("usd")
                                .font(.Main.fixed(.monoMedium, size: 12))
                                .foregroundColor(Palette.grayScale6A)
                                .offset(x: -1, y: 5)
                        }
                        
                    }
                }
                
                if let notes = viewModel.tx.notes {
                    Text(notes)
                        .multilineTextAlignment(.leading)
                        .font(.Main.fixed(.monoRegular, size: 14))
                        .foregroundColor(Palette.grayScaleAA)
                        .padding(.leading, 40)
                }
                
                if let labels = viewModel.tx.labels {
                    WrappedHStack(labels) { label in
                        TxLabelView(label: label)
                    }
                    .padding(.leading, 35)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            
            Divider()
                .overlay(Color(red: 26/255, green: 26/255, blue: 26/255))
        }
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = viewModel.tx.txid}) {
                    Text("Copy TXID")
                }
        }
    }
}

struct SingleTxView_Previews: PreviewProvider {
    static var previews: some View {
        let blockTime = BlockTime(height: 20087, timestamp: 1635863544)
        let details = TransactionDetails(fee: 300, received: 0, sent: 1000, txid: "some-other-tx-id", confirmationTime: blockTime)
        
        SingleTxView(transaction: details)
            .padding(.horizontal)
    }
}
