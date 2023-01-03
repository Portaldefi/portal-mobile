//
//  ISendAssetService.swift
//  Portal
//
//  Created by farid on 1/3/23.
//

import Foundation
import Combine

protocol ISendAssetService {
    var balance: Decimal { get }
    var spendable: Decimal { get }
    var fee: Decimal { get }
    
    var amount: CurrentValueSubject<Decimal, Never> { get }
    var feeRate: CurrentValueSubject<Int, Never> { get }
    var receiverAddress: CurrentValueSubject<String, Never> { get }
    
    var feeRateProvider: IFeeRateProvider { get }
    
    func validateAddress() throws
    func send() -> Future<Void, Error>
}
