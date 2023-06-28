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

class ActivityViewModel: ObservableObject {
    
    var keyboardPublisher: AnyPublisher<Bool, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .map { _ in true },
            
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in false }
        )
        .eraseToAnyPublisher()
    }
    
    @Published var selectedTx: TransactionRecord?
    @Published private(set) var transactions = [TransactionRecord]()
    @Published private(set) var searchResults = [TransactionRecord]()
    @Published var searchContext = String()
    @Injected(Container.viewState) var viewState
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        updateTransactions()
        
        $searchContext.sink { [unowned self] context in
            guard !context.isEmpty else { return }
            let searchContext = context.lowercased()
            self.searchResults = transactions.filter {
                $0.coin.name.lowercased().contains(searchContext) ||
                $0.coin.code.lowercased().contains(searchContext) ||
                String(describing: $0.amount ?? 0).lowercased().contains(searchContext) ||
                $0.notes?.lowercased().contains(searchContext) ?? false ||
                !$0.labels.filter{ $0.label.contains(searchContext) }.isEmpty ||
                $0.type.description.lowercased().contains(searchContext)
            }
        }
        .store(in: &subscriptions)
    }
    
    func updateTransactions() {
        subscriptions.removeAll()
        transactions.removeAll()
        
        let adapterManager: IAdapterManager = Container.adapterManager()
        let walletManager: IWalletManager = Container.walletManager()
        
        Publishers.MergeMany(
            walletManager.activeWallets
                .compactMap { adapterManager.transactionsAdapter(for: $0) }
                .compactMap { $0.transactionRecords }
        )
        .flatMap { Publishers.Sequence(sequence: $0) }
        .receive(on: RunLoop.main)
        .sink { [weak self] transactionRecord in
            guard let self = self else { return }
            let index = self.transactions.firstIndex { $0.timestamp ?? 1 < transactionRecord.timestamp ?? 1 } ?? self.transactions.endIndex
            self.transactions.insert(transactionRecord, at: index)
        }
        .store(in: &subscriptions)
    }
}

struct ActivityView: View {
    @StateObject private var viewModel = ActivityViewModel()
    
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
                
                TextField("Search", text: $viewModel.searchContext)
                    .disableAutocorrection(true)
                    .font(.Main.fixed(.monoRegular, size: 16))
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Palette.grayScale3A, lineWidth: 1)
                            .frame(height: 40)
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
                    .onReceive(viewModel.keyboardPublisher) { newIsKeyboardVisible in
                        Container.viewState().hideTabBar = newIsKeyboardVisible
                    }
            }
            .padding(.horizontal, 8)
            
            Divider()
                .overlay(Palette.grayScale10)
            
            ZStack {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.searchContext.isEmpty ? viewModel.transactions : viewModel.searchResults, id: \.self) { transaction in
                            SingleTxView(transaction: transaction)
                                .padding(.leading, 10)
                                .padding(.trailing, 6)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.selectedTx = transaction
                                }
                        }
                    }
                    .padding(.bottom, viewModel.viewState.hideTabBar ? 0 : 65)
                }
                .background(Palette.grayScale20)
                
                if viewModel.transactions.isEmpty {
                    Text("No transactions yet.")
                        .font(.Main.fixed(.monoRegular, size: 16))
                        .padding()
                }
            }
        }
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale1A))
        .sheet(item: $viewModel.selectedTx, onDismiss: {
            DispatchQueue.main.async {
                viewModel.updateTransactions()
            }
        }) { tx in
            TransactionDetailsView(coin: tx.coin, tx: tx).lockableView()
        }
    }
}

struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView()
    }
}
