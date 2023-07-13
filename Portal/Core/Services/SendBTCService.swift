//
//  SendBTCService.swift
//  Portal
//
//  Created by farid on 1/4/23.
//

import Foundation
import Combine
import BitcoinDevKit
import Factory

class SendBTCService: ISendAssetService {
    private var url: URL? = URL(string: "https://api.blockcypher.com/v1/btc/test3")
    private var urlSession: URLSession
    private let sendAdapter: ISendBitcoinAdapter
    private var subscriptions = Set<AnyCancellable>()
        
    var amount = CurrentValueSubject<Decimal, Never>(0)
    var receiverAddress = CurrentValueSubject<String, Never>(String())
    var feeRateType = CurrentValueSubject<TxFees, Never>(.normal)
    var recomendedFees = CurrentValueSubject<RecomendedFees?, Never>(nil)
    
    var balance: Decimal {
        sendAdapter.balance
    }
    
    var spendable: Decimal {
        balance - (fee/100_000_000)
    }
    
    var fee: Decimal = 0
    
    private var recomendedFee: Int? {
        (self.recomendedFees.value?.fee(feeRateType.value) as? NSDecimalNumber)?.intValue
    }

    init(sendAdapter: ISendBitcoinAdapter) {
        self.sendAdapter = sendAdapter
        
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        
        self.urlSession = URLSession(configuration: config)
        
        updateRecomendedFees()
        
        Publishers.CombineLatest3(amount, receiverAddress, feeRateType)
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .filter{ amount, address, _ in
                amount > 0 && !address.isEmpty
            }
            .flatMap{ amount, address, feeRateType -> AnyPublisher<UInt64?, Never> in
                print("send btc service amount = \(String(describing: amount))")
                
                do {
                    let result = try self.validateUserInput()
                    
                    switch result {
                    case .btcOnChain(let address):
                        let txFee = try self.sendAdapter.fee(
                            max: amount == self.spendable,
                            address: address,
                            amount: amount,
                            fee: self.recomendedFee
                        )
                        
                        return Just(txFee).eraseToAnyPublisher()
                    case .lightningInvoice, .ethOnChain:
                        return Just(nil).eraseToAnyPublisher()
                    }
                } catch {
                    print(error)
                    return Just(nil).eraseToAnyPublisher()
                }
            }
            .receive(on: RunLoop.main)
            .sink { fee in
                guard let fee = fee else { return }
                print("btc tx fee = \(fee)")
                self.fee = Decimal(fee)
            }
            .store(in: &subscriptions)
    }
    
    private func updateRecomendedFees() {
        guard let url = self.url else { return }
        
        urlSession.dataTaskPublisher(for: url)
            .tryMap { $0.data }
            .decode(type: RecomendedFees.self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .sink { completion in
                if case let .failure(error) = completion {
                    print(error.localizedDescription)
                }
            } receiveValue: { [weak self] response in
                self?.recomendedFees.send(response)
            }
            .store(in: &subscriptions)
    }
    
    func validateUserInput() throws -> UserInputResult {
        let ldkManager = Container.lightningKitManager()
        let inputString = receiverAddress.value
        
        do {
            let invoice = try ldkManager.decode(invoice: inputString)
            if let value = invoice.amountMilliSatoshis() {
                return .lightningInvoice(amount: String(describing: Decimal(value)/1000/100_000_000))
            } else {
                return .lightningInvoice(amount: String())
            }
        } catch {
            print("user input isn't invoice")
        }
        
        do {
            try sendAdapter.validate(address: inputString)
            return .btcOnChain(address: inputString)
        } catch {
            print("user input isn't on chain address")
        }
        
        throw SendFlowError.addressIsntValid
    }
    
    func send() async throws -> TransactionRecord {
        let result = try validateUserInput()
        switch result {
        case .btcOnChain:
            return try sendAdapter.send(amount: amount.value, address: receiverAddress.value, fee: self.recomendedFee)
        case .lightningInvoice:
            let manager = Container.lightningKitManager()
            
            return try await manager.pay(invoice: receiverAddress.value)
        case .ethOnChain:
            return try sendAdapter.send(amount: amount.value, address: receiverAddress.value, fee: self.recomendedFee)
        }
    }
    
    func sendMax() async throws -> TransactionRecord {
        try sendAdapter.sendMax(address: receiverAddress.value, fee: self.recomendedFee)
    }
}
