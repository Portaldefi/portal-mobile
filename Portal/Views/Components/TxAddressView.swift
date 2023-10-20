//
//  TxAddressView.swift
// Portal
//
//  Created by farid on 10/2/22.
//

import SwiftUI
import PortalUI

struct TxAddressView: View {
    let title: String
    let address: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.Main.fixed(.monoBold, size: 14))
                .foregroundColor(Palette.grayScaleAA)
            Spacer()
            Text(address)
                .font(.Main.fixed(.monoRegular, size: 16))
                .foregroundColor(Palette.grayScaleF4)
        }
        .frame(minHeight: 52)
    }
}

struct TxRecipientView_Previews: PreviewProvider {
    static var previews: some View {
        TxAddressView(title: "Recipient", address: "bc1saiUIFSksaoasdhVDPASDJNSAasdijsasdjkhasdkaso3njxks")
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
