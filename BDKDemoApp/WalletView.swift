//
//  WalletView.swift
//  BDKDemoApp
//
//  Created by farid on 7/20/22.
//

import SwiftUI

struct WalletView: View {
    var body: some View {
        Text("BDKDemo")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        WalletView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
