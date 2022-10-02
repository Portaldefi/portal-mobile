//
//  TxRecipientView.swift
//  BDKDemoApp
//
//  Created by farid on 10/2/22.
//

import SwiftUI
import PortalUI

struct TxRecipientView: View {
    let recipient: String
    
    var body: some View {
        HStack {
            Text("Recipient")
                .font(.Main.fixed(.monoBold, size: 14))
                .foregroundColor(Palette.grayScaleAA)
            Spacer()
            Text(recipient)
                .font(.Main.fixed(.monoRegular, size: 16))
                .foregroundColor(Palette.grayScaleF4)
        }
        .frame(height: 72)
    }
}

struct TxRecipientView_Previews: PreviewProvider {
    static var previews: some View {
        TxRecipientView(recipient: "bc1saiUIFSksaoasdhVDPASDJNSAasdijsasdjkhasdkaso3njxks")
    }
}
