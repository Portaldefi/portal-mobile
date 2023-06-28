//
//  NumpadView.swift
//  Portal
//
//  Created by farid on 27.06.2023.
//

import SwiftUI

struct NumpadView: View {
    private(set) var onAdd: (Int) -> ()
    private(set) var onRemove: () -> ()
    
    init(onAdd: @escaping (Int) -> (), onRemove: @escaping () -> ()) {
        self.onAdd = onAdd
        self.onRemove = onRemove
    }
    
    var body: some View {
        VStack(spacing: 44) {
            ForEach(0..<3) { i in
                HStack(spacing: 0) {
                    ForEach(1...3, id:\.self) { j in
                        Button(action: {
                            onAdd(i*3 + j)
                        }) {
                            Text("\(i*3 + j)")
                                .font(.Main.fixed(.monoBold, size: 24))
                        }
                    }
                }
            }
            HStack(spacing: 0) {
                Circle()
                    .frame(height: 45)
                    .frame(maxWidth: .infinity)
                    .opacity(0)
                
                Button(action: {
                    onAdd(0)
                }) {
                    Text("0")
                        .font(.Main.fixed(.monoBold, size: 24))
                }
                
                Button(action: {
                    onRemove()
                }) {
                    Image(systemName: "delete.left")
                        .font(.Main.fixed(.monoBold, size: 24))
                }
                .offset(y: -5)
            }
        }
        .buttonStyle(PinButtonStyle())
    }
}


struct NumpadView_Previews: PreviewProvider {
    static var previews: some View {
        NumpadView(onAdd: {_ in }, onRemove: {})
    }
}
