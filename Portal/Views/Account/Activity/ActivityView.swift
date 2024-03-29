//
//  ActivityView.swift
//  Portal
//
//  Created by farid on 16.06.2023.
//

import SwiftUI
import PortalUI
import Factory
import Combine

struct ActivityView: View {
    @StateObject private var viewModel = ActivityViewModel.config()
    @State private var viewState = Container.viewState()
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack {
                    Text("Activity")
                        .font(.Main.fixed(.monoBold, size: 24))
                        .foregroundColor(Palette.grayScaleCA)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Palette.grayScale4A)
                        
                        TextField("Search", text: $viewModel.searchContext)
                            .disableAutocorrection(true)
                            .font(.Main.fixed(.monoRegular, size: 16))
                    }
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Palette.grayScale3A, lineWidth: 1)
                            .frame(height: 40)
                    )
                    .padding(.bottom, 4)
                    .onReceive(viewModel.keyboardPublisher) { newIsKeyboardVisible in
                        viewState.hideTabBar = newIsKeyboardVisible
                    }
                    .layoutPriority(1)
                    
                    Menu {
                        // An expandable submenu
                        Menu {
                            Button(action: { viewModel.updateTxTypeFilter(filter: .none) }) {
                                Text("None")
                                if viewModel.txTypeFilter == .none {
                                    Image(systemName: "checkmark")
                                }
                            }
                            
                            Button(action: { viewModel.updateTxTypeFilter(filter: .sent) }) {
                                Text("Sent")
                                if viewModel.txTypeFilter == .sent {
                                    Image(systemName: "checkmark")
                                }
                            }
                            
                            Button(action: { viewModel.updateTxTypeFilter(filter: .received) }) {
                                Text("Received")
                                if viewModel.txTypeFilter == .received {
                                    Image(systemName: "checkmark")
                                }
                            }
                            
                            Button(action: { viewModel.updateTxTypeFilter(filter: .swap) }) {
                                Text("Swaps")
                                if viewModel.txTypeFilter == .swap {
                                    Image(systemName: "checkmark")
                                }
                            }
                            
                            Divider()
                            
                            Button(action: { viewModel.updateTxTypeFilter(filter: .success) }) {
                                Text("Success")
                                if viewModel.txTypeFilter == .success {
                                    Image(systemName: "checkmark")
                                }
                            }
                            
                            Button(action: { viewModel.updateTxTypeFilter(filter: .failed) }) {
                                Text("Failed")
                                if viewModel.txTypeFilter == .failed {
                                    Image(systemName: "checkmark")
                                }
                            }
                            
                            Button(action: { viewModel.updateTxTypeFilter(filter: .pending) }) {
                                Text("Pending")
                                if viewModel.txTypeFilter == .pending {
                                    Image(systemName: "checkmark")
                                }
                            }
                        } label: {
                            Label {
                                Text("Filter")
                            } icon: {
                                Image(systemName: "slider.vertical.3")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(Palette.grayScale6A)
                            }
                        }
                        
                        Divider()
                        
                        Menu {
                            Button(action: { viewModel.updateSort(sort: .date) }) {
                                Text("Date")
                                if viewModel.selectedSort == .date {
                                    Image(systemName: "checkmark")
                                }
                            }
                            
                            Button(action: { viewModel.updateSort(sort: .amount) }) {
                                Text("Amount")
                                if viewModel.selectedSort == .amount {
                                    Image(systemName: "checkmark")
                                }
                            }
                            
                            Button(action: { viewModel.updateSort(sort: .coin) }) {
                                Text("Coin")
                                if viewModel.selectedSort == .coin {
                                    Image(systemName: "checkmark")
                                }
                            }
                            
                            Divider()
                            
                            Button(action: { viewModel.toggleSortOrder() }) {
                                Text("Ascending")
                                if !viewModel.isDescending {
                                    Image(systemName: "checkmark")
                                }
                            }
                            
                            Button(action: { viewModel.toggleSortOrder() }) {
                                Text("Descending")
                                if viewModel.isDescending {
                                    Image(systemName: "checkmark")
                                }
                            }
                            
                        } label: {
                            Label {
                                Text("Sort By")
                            } icon: {
                                Image(systemName: "arrow.up.arrow.down")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(Palette.grayScale6A)
                            }
                        }
                    } label: {
                        Image(systemName: "slider.vertical.3")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Palette.grayScale6A)
                    }
                    .padding(.leading, 16)
                }
                .padding(.leading, 8)
                .padding(.trailing, 16)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
            
            Divider()
                .overlay(Palette.grayScale10)
            
            ZStack {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(
                            viewModel.searchContext.isEmpty ? viewModel.filteredTransactions : viewModel.searchResults,
                            id: \.self
                        ) { transaction in
                            SingleTxView(searchContext: viewModel.searchContext, transaction: transaction)
                                .padding(.leading, 10)
                                .padding(.trailing, 6)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.selectedTx = transaction
                                }
                        }
                    }
                    .padding(.bottom, viewState.hideTabBar ? 0 : 65)
                }
                .background(Palette.grayScale20)
                .refreshable {
                    viewModel.updateTransactions()
                }
                
                if viewModel.searchContext.isEmpty && viewModel.filteredTransactions.isEmpty {
                    Text("No transactions yet.")
                        .font(.Main.fixed(.monoRegular, size: 16))
                        .padding()
                }
            }
        }
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale1A))
        .onAppear {
            viewModel.updateTransactions()
        }
        .sheet(isPresented: $viewState.showQRCodeScannerFromTabBar) {
            QRCodeReaderRootView(config: .universal).lockableView()
        }
        .sheet(item: $viewModel.selectedTx) { tx in
            switch tx.type {
            case .sent(let coin), .received(let coin), .swap(let coin, _):
                TransactionView(coin: coin, tx: tx).lockableView()
            case .unknown:
                EmptyView()
            }
        }
    }
}

struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView()
    }
}
