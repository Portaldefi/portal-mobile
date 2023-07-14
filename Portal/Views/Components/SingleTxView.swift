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
    let searchContext: String?
    
    @ObservedObject var viewModel: SingleTxViewModel
    
    init(searchContext: String? = nil, transaction: TransactionRecord) {
        self.searchContext = searchContext
        self._viewModel = ObservedObject(initialValue: SingleTxViewModel(tx: transaction))
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
                    case .unknown:
                        Circle()
                            .frame(width: 24, height: 24)
                            .offset(y: -6)
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        HighlightedText(
                            text: viewModel.tx.type.description,
                            textColor: Palette.grayScaleEA,
                            highlight: searchContext,
                            font: .Main.fixed(.monoMedium, size: 16),
                            highlightFont: .Main.fixed(.monoBold, size: 16)
                        )

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
                                HighlightedText(
                                    text: viewModel.amount,
                                    textColor: viewModel.tx.type == .received ? Color(red: 0.191, green: 0.858, blue: 0.418) : Palette.grayScaleEA,
                                    highlight: searchContext,
                                    font: .Main.fixed(.monoMedium, size: 16),
                                    highlightFont: .Main.fixed(.monoBold, size: 16)
                                )
                            }
                            HStack {
                                Text("\(viewModel.tx.type == .received ? "+" : "-")")
                                    .font(.Main.fixed(.monoBold, size: 16))
                                    .foregroundColor(Palette.grayScale6A)
                                Text(viewModel.value)
                                    .font(.Main.fixed(.monoRegular, size: 16))
                                    .foregroundColor(Palette.grayScale6A)
                                    .offset(x: 1)
                            }
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                HighlightedText(
                                    text: viewModel.tx.coin.code.uppercased(),
                                    textColor: Palette.grayScale6A,
                                    highlight: searchContext,
                                    font: .Main.fixed(.monoMedium, size: 12),
                                    highlightFont: .Main.fixed(.monoBold, size: 16)
                                )
                                .offset(y: -1)
                                
                                Spacer()
                            }
                            .frame(width: 38)
                            
                            Text(viewModel.fiatCurrency.code.uppercased())
                                .font(.Main.fixed(.monoMedium, size: 12))
                                .foregroundColor(Palette.grayScale6A)
                                .offset(x: 1, y: 4)
                        }
                        
                    }
                }
                
                if let notes = viewModel.tx.notes, !notes.isEmpty {
                    HighlightedText(
                        text: notes,
                        textColor: Palette.grayScaleAA,
                        highlight: searchContext,
                        font: .Main.fixed(.monoRegular, size: 14),
                        highlightFont: .Main.fixed(.monoBold, size: 14)
                    )
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 40)
                    .padding(.trailing, 8)
                }

                if let labels = viewModel.tx.labels, !labels.isEmpty {
                    WrappedHStack(labels) { label in
                        TxLabelView(searchContext: searchContext, label: label)
                    }
                    .padding(.leading, 35)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            
            Divider()
                .overlay(Color(red: 26/255, green: 26/255, blue: 26/255))
                .frame(height: 2)
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
        SingleTxView(transaction: TransactionRecord.mocked)
            .padding(.horizontal)
            .previewLayout(.sizeThatFits)
    }
}
