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
    private let adapter: ISendBitcoinAdapter
    private var subscriptions = Set<AnyCancellable>()
        
    var amount = CurrentValueSubject<Decimal, Never>(0)
    var receiver = CurrentValueSubject<String, Never>(String())
    var feeRateType = CurrentValueSubject<TxFees, Never>(.normal)
    var recomendedFees = CurrentValueSubject<RecomendedFees?, Never>(nil)
    
    var balance: Decimal {
        adapter.balance
    }
    
    var spendable: Decimal {
        balance - (fee/100_000_000)
    }
    
    var fee: Decimal = 0
    
    private var recomendedFee: Int? {
        (self.recomendedFees.value?.fee(feeRateType.value) as? NSDecimalNumber)?.intValue
    }

    init(adapter: ISendBitcoinAdapter) {
        self.adapter = adapter
        
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        
        self.urlSession = URLSession(configuration: config)
        
        updateRecomendedFees()
        
        Publishers.CombineLatest3(amount, receiver, feeRateType)
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .filter{ amount, address, _ in
                amount > 0 && !address.isEmpty
            }
            .flatMap{ [unowned self] amount, address, feeRateType -> AnyPublisher<UInt64?, Never> in
                print("send btc service amount = \(String(describing: amount))")
                
                do {
                    let result = try self.validateUserInput()
                    
                    let txFee = try self.adapter.fee(
                        max: amount == self.spendable,
                        address: address,
                        amount: amount,
                        fee: self.recomendedFee
                    )
                    
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
    
    func validateUserInput() throws -> UserInputResult {
        let inputString = receiver.value
        try adapter.validate(address: inputString)
        return .btcOnChain(address: inputString)
    }
    
    func send() async throws -> TransactionRecord {
        try adapter.send(amount: amount.value, address: receiver.value, fee: self.recomendedFee)
    }
    
    func sendMax() async throws -> TransactionRecord {
        try adapter.sendMax(address: receiver.value, fee: self.recomendedFee)
    }
}
