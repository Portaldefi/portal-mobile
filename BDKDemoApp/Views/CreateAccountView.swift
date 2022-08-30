//
//  CreateAccountView.swift
//  BDKDemoApp
//
//  Created by farid on 8/9/22.
//

import SwiftUI
import PortalUI

struct CreateAccountView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var viewModel = CreateAccountViewModel()
    
    init() {
        UITableView.appearance().backgroundColor = .clear
    }
    
    var body: some View {
        ZStack {
            Color(red: 10/255, green: 10/255, blue: 10/255, opacity: 1).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    HStack {
                        PButton(config: .onlyIcon(Asset.arrowLeftIcon), style: .free, size: .medium, enabled: true) {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .frame(width: 20)
                        
                        Spacer()
                    }
                    
                    Text("Create account")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .frame(height: 62)
                }
                
                HStack {
                    Text("Account Name")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                    Spacer()
                }
                
                TextField("Required", text: $viewModel.accountName)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .font(Font.system(size: 16, weight: .bold, design: .monospaced))
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                Color(red: 26/255, green: 26/255, blue: 26/255)
                            )
                    )
                
                Spacer()
                
                PButton(config: .onlyLabel("Confirm"), style: .filled, size: .big, enabled: !viewModel.accountName.isEmpty) {
                    viewModel.createAccount()
                }
            }
            .padding(.bottom, 157)
            .padding([.top, .horizontal])
            
//            VStack {
////                Form {
////                    Section(header: Text("Account name").textStyle(BasicTextStyle(white: true))) {
////                        TextField("Required", text: $viewModel.accountName)
////                            .disableAutocorrection(true)
////                            .textInputAutocapitalization(.never)
////                            .font(Font.system(size: 16, weight: .bold, design: .monospaced))
////                            .background(
////                                RoundedRectangle(cornerRadius: 12)
////                                    .fill(
////                                        Color(red: 26/255, green: 26/255, blue: 26/255)
////                                    )
////                            )
////                    }
////
//////                    Section(header: Text("SEED").textStyle(BasicTextStyle(white: true))) {
//////                        Text(viewModel.extendedKey.mnemonic)
//////                            .foregroundColor(.white)
//////                            .font(.system(size: 14, design: .monospaced))
//////                            .fontWeight(.semibold)
//////                    }
////                }
//
//                Spacer()
//
//                PButton(config: .onlyLabel("Confirm"), style: .filled, size: .big, enabled: !viewModel.accountName.isEmpty) {
//                    viewModel.createAccount()
//                }
//                .padding(.bottom, 157)
//            }
        }
        .navigationBarHidden(true)
        .modifier(BackButtonModifier())
    }
}

struct CreateWalletView_Previews: PreviewProvider {
    static var previews: some View {
        CreateAccountView()
    }
}
