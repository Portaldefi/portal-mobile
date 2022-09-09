//
//  WalletItemView.swift
//  BDKDemoApp
//
//  Created by farid on 25/8/22.
//

import SwiftUI
import PortalUI

struct WalletItemView: View {
    let item: WalletItem
    var body: some View {
        HStack {
            VStack(spacing: 12) {
                VStack(spacing: 4.2) {
                    HStack(spacing: 6) {
                        item.icon
                        Text(item.name)
                            .font(.Main.fixed(.bold, size: 16))
                            .foregroundColor(Color(red: 202/255, green: 202/255, blue: 202/255, opacity: 1))
                            .frame(height: 16)
                        Spacer()
                    }
                    HStack(spacing: 4) {
                        Text("on")
                            .font(.Main.fixed(.medium, size: 12))
                            .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                            .frame(height: 17)
                        item.chainIcon.resizable()
                            .frame(width: 12, height: 12)
                            .foregroundColor(Color(red: 138/255, green: 138/255, blue: 138/255, opacity: 1))
                        Text(item.description)
                            .font(.Main.fixed(.medium, size: 12))
                            .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                            .frame(height: 17)
                        Spacer()
                    }
                }
            }
            Spacer()
            HStack(spacing: 6) {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(item.balance)")
                        .font(.Main.fixed(.bold, size: 20))
                        .foregroundColor(Color(red: 234/255, green: 234/255, blue: 234/255, opacity: 1))
                    Text(item.value)
                        .font(.Main.fixed(.medium, size: 16))
                        .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                        .offset(x: 1)
                }
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(item.unit)
                            .font(.Main.fixed(.medium, size: 12))
                            .foregroundColor(Color(red: 170/255, green: 170/255, blue: 170/255, opacity: 1))
                        Spacer()
                    }
                    .frame(width: 40)
                    Text("usd")
                        .font(.Main.fixed(.medium, size: 12))
                        .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                        .offset(x: -1, y: 7)
                }
            }
        }
        .frame(height: 70)
    }
}

struct WalletItemView_Previews: PreviewProvider {
    static var previews: some View {
        WalletItemView(item: WalletItem(
            icon: Asset.btcIcon,
            chainIcon: Asset.chainIcon,
            name: "Bitcoin",
            description: "Chain",
            balance: "0.00124",
            unit: "btc",
            value: "$ 4.2")
        )
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding()
    }
}
