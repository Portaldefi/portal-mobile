//
//  ContentView.swift
//  BDKDemoApp
//
//  Created by farid on 7/20/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("BDKDemo")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
