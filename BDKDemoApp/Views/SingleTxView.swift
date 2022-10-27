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
    var transaction: BitcoinDevKit.TransactionDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                if transaction.sent > 0 {
                    Asset.txSentIcon.cornerRadius(16)
                } else {
                    Asset.txReceivedIcon.cornerRadius(16)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(transaction.txid)
                        .lineLimit(1)
                        .font(.Main.fixed(.monoBold, size: 16))
                        .foregroundColor(Palette.grayScaleCA)
                    if let confirmation = transaction.confirmationTime {
                        Text(Date(timeIntervalSince1970: TimeInterval(confirmation.timestamp)).formatted())
                            .font(.Main.fixed(.monoRegular, size: 14))
                            .lineLimit(1)
                            .foregroundColor(Palette.grayScale6A)
                    }
                }
                .frame(width: 125)
                Spacer()
                HStack(spacing: 6) {
                    VStack(alignment: .trailing, spacing: 0) {
                        HStack {
                            Text("\(transaction.sent > 0 ? "-" : "+")")
                                .font(.Main.fixed(.monoBold, size: 16))
                                .foregroundColor(Palette.grayScaleEA)
                            Text(transaction.sent > 0 ? "\(Double(transaction.sent)/100_000_000)" : "\(Double(transaction.received)/100_000_000)")
                                .font(.Main.fixed(.monoMedium, size: 16))
                                .foregroundColor(Palette.grayScaleEA)
                        }
                        HStack {
                            Text("\(transaction.sent > 0 ? "-" : "+")")
                                .font(.Main.fixed(.monoBold, size: 16))
                            Text("$4.55")
                                .font(.Main.fixed(.monoMedium, size: 16))
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
        }
        .frame(height: 76)
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = transaction.txid}) {
                    Text("Copy TXID")
                }
        }
    }
}

struct SingleTxView_Previews: PreviewProvider {
    static var previews: some View {
        SingleTxView(transaction: TransactionDetails(fee: 300, received: 0, sent: 1000, txid: "some-other-tx-id", confirmationTime: BlockTime(height: 20087, timestamp: 1635863544)))
    }
}
