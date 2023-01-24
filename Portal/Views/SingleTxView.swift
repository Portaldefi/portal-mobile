//
//  SingleTxView.swift
//  Portal
//
//  Created by farid on 7/21/22.
//

import SwiftUI
import BitcoinDevKit
import PortalUI

struct SingleTxView: View {
    @ObservedObject var viewModel: SingleTxViewModel
    
    init(coin: Coin, transaction: TransactionRecord) {
        self._viewModel = ObservedObject(initialValue: SingleTxViewModel(coin: coin, tx: transaction))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    switch viewModel.tx.type {
                    case .sent:
                        Asset.txSentIcon.cornerRadius(16)
                            .offset(y: -6)
                    case .received:
                        Asset.txReceivedIcon.cornerRadius(16)
                            .offset(y: -6)
                    case .swapped:
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
                                Text("\(viewModel.tx.type == .received ? "+" : "-")")
                                    .font(.Main.fixed(.monoMedium, size: 16))
                                    .foregroundColor(viewModel.tx.type == .received ? Color(red: 0.191, green: 0.858, blue: 0.418) : Palette.grayScaleEA)
                                Text(viewModel.value)
                                    .font(.Main.fixed(.monoMedium, size: 16))
                                    .foregroundColor(viewModel.tx.type == .received ? Color(red: 0.191, green: 0.858, blue: 0.418) : Palette.grayScaleEA)
                            }
                            HStack {
                                Text("\(viewModel.tx.type == .received ? "+" : "-")")
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
                                Text(viewModel.coin.code.lowercased())
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
                        .padding(.trailing, 8)
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
                UIPasteboard.general.string = viewModel.tx.id}) {
                    Text("Copy TXID")
                }
        }
    }
}

struct SingleTxView_Previews: PreviewProvider {
    static var previews: some View {
        SingleTxView(coin: .bitcoin(), transaction: TransactionRecord.mocked)
            .padding(.horizontal)
    }
}
