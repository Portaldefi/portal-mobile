//
//  SingleTxView.swift
//  BDKDemoApp
//
//  Created by farid on 7/21/22.
//

import SwiftUI
import BitcoinDevKit
import PortalUI

extension BitcoinDevKit.Transaction {
    public func getDetails() -> TransactionDetails {
        switch self {
        case .unconfirmed(let details): return details
        case .confirmed(let details, _): return details
        }
    }
}

struct SingleTxView: View {
    var transaction: BitcoinDevKit.Transaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            switch transaction {
            case .unconfirmed(let details):
                HStack(spacing: 8) {
                    if details.sent > 0 {
                        Asset.txSentIcon.cornerRadius(16)
                    } else {
                        Asset.txReceivedIcon.cornerRadius(16)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text(details.txid)
                            .lineLimit(1)
                            .font(.Main.fixed(.bold, size: 16))
                            .foregroundColor(Color(red: 202/255, green: 202/255, blue: 202/255))
                        Text("Not confirmed")
                            .font(.Main.fixed(.regular, size: 14))
                            .lineLimit(1)
                            .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255))
                    }
                    .frame(width: 125)
                    Spacer()
                    HStack(spacing: 6) {
                        VStack(alignment: .trailing, spacing: 0) {
                            HStack {
                                Text("\(details.sent > 0 ? "-" : "+")")
                                    .font(.Main.fixed(.bold, size: 16))
                                    .foregroundColor(Color(red: 234/255, green: 234/255, blue: 234/255, opacity: 1))
                                Text(details.sent > 0 ? "\(Double(details.sent)/100_000_000)" : "\(Double(details.received)/100_000_000)")
                                    .font(.Main.fixed(.medium, size: 16))
                                    .foregroundColor(Color(red: 234/255, green: 234/255, blue: 234/255, opacity: 1))
                            }
                            HStack {
                                Text("\(details.sent > 0 ? "-" : "+")")
                                    .font(.Main.fixed(.bold, size: 16))
                                Text("$4.55")
                                    .font(.Main.fixed(.medium, size: 16))
                                    .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                                    .offset(x: 1)
                            }
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("btc")
                                    .font(.Main.fixed(.medium, size: 12))
                                    .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                                    .offset(y: -1)
                                Spacer()
                            }
                            .frame(width: 30)
                            Text("usd")
                                .font(.Main.fixed(.medium, size: 12))
                                .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                                .offset(x: -1, y: 5)
                        }

                    }
                }
            case .confirmed(let details, let confirmation):
                HStack(spacing: 8) {
                    if details.sent > 0 {
                        Asset.txSentIcon.cornerRadius(16)
                    } else {
                        Asset.txReceivedIcon.cornerRadius(16)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text(details.txid)
                            .lineLimit(1)
                            .font(.Main.fixed(.bold, size: 16))
                            .foregroundColor(Color(red: 202/255, green: 202/255, blue: 202/255))
                        Text(Date(timeIntervalSince1970: TimeInterval(confirmation.timestamp)).formatted())
                            .font(.Main.fixed(.regular, size: 14))
                            .lineLimit(1)
                            .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255))
                    }
                    .frame(width: 125)
                    Spacer()
                    HStack(spacing: 6) {
                        VStack(alignment: .trailing, spacing: 0) {
                            HStack {
                                Text("\(details.sent > 0 ? "-" : "+")")
                                    .font(.Main.fixed(.bold, size: 16))
                                    .foregroundColor(Color(red: 234/255, green: 234/255, blue: 234/255, opacity: 1))
                                Text(details.sent > 0 ? "\(Double(details.sent)/100_000_000)" : "\(Double(details.received)/100_000_000)")
                                    .font(.Main.fixed(.medium, size: 16))
                                    .foregroundColor(Color(red: 234/255, green: 234/255, blue: 234/255, opacity: 1))
                            }
                            HStack {
                                Text("\(details.sent > 0 ? "-" : "+")")
                                    .font(.Main.fixed(.bold, size: 16))
                                Text("$4.55")
                                    .font(.Main.fixed(.medium, size: 16))
                                    .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                                    .offset(x: 1)
                            }
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("btc")
                                    .font(.Main.fixed(.medium, size: 12))
                                    .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                                    .offset(y: -1)
                                Spacer()
                            }
                            .frame(width: 30)
                            Text("usd")
                                .font(.Main.fixed(.medium, size: 12))
                                .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                                .offset(x: -1, y: 5)
                        }

                    }
                }
            }
        }
        .frame(height: 76)
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = transaction.getDetails().txid}) {
                    Text("Copy TXID")
                }
        }
    }
}

struct SingleTxView_Previews: PreviewProvider {
    static var previews: some View {
        SingleTxView(transaction: Transaction.confirmed(details: TransactionDetails(fee: nil, received: 1000, sent: 10000, txid: "some-other-tx-id"), confirmation: BlockTime(height: 20087, timestamp: 1635863544)))
    }
}
