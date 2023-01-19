//
//  SendBTCService.swift
//  Portal
//
//  Created by farid on 1/4/23.
//

import Foundation
import Combine
import BitcoinDevKit

class SendBTCService: ISendAssetService {
    private var url: URL? = URL(string: "https://bitcoinfees.earn.com/api/v1/fees/recommended")
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
                
                guard amount > 0, !address.isEmpty else {
                    return Just(nil).eraseToAnyPublisher()
                }
                
                do {
                    try self.validateAddress()
                    var fee: Int? = nil
                    if let recommendedFees = self.recomendedFees.value {
                        fee = (recommendedFees.fee(feeRateType) as NSDecimalNumber).intValue
                    }
                    let txFee = try self.sendAdapter.fee(max: amount == self.spendable, address: address, amount: amount, fee: fee)
                    return Just(txFee).eraseToAnyPublisher()
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
    
    func validateAddress() throws {
        try sendAdapter.validate(address: receiverAddress.value)
    }
    
    func send() -> Future<String, Error> {
        var fee: Int? = nil

        if let recommendedFees = self.recomendedFees.value {
            fee = (recommendedFees.fee(feeRateType.value) as NSDecimalNumber).intValue
        }
        
        return sendAdapter.send(amount: amount.value, address: receiverAddress.value, fee: fee)
    }
    
    func sendMax() -> Future<String, Error> {
        var fee: Int? = nil

        if let recommendedFees = self.recomendedFees.value {
            fee = (recommendedFees.fee(feeRateType.value) as NSDecimalNumber).intValue
        }
        
        return sendAdapter.sendMax(address: receiverAddress.value, fee: fee)
    }
    
    func unconfirmedTx(id: String, amount: String) -> TransactionRecord {
        let unconfirmedTx = BitcoinDevKit.TransactionDetails.unconfirmedSentTransaction(
            recipient: receiverAddress.value,
            amount: amount,
            id: id
        )
        
        return TransactionRecord(transaction: unconfirmedTx)
    }
}
