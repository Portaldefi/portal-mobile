//
//  AtomicHolderTemplate.swift
//  Portal
//
//  Created by farid on 5/5/23.
//

import Foundation
import Factory
import HsCryptoKit
import EvmKit
import BigInt

class CreateInvoiceMethod: ContractMethod {
    private let tokenAddress: Address
    private let tokenAmount: BigUInt
    private let tokenNetwork: BigUInt

    init(tokenAddress: Address, tokenAmount: BigUInt, tokenNetwork: BigUInt) {
        self.tokenAddress = tokenAddress
        self.tokenAmount = tokenAmount
        self.tokenNetwork = tokenNetwork
        super.init()
    }

    override var methodSignature: String {
        return "createInvoice(address,uint256,uint256)"
    }

    override var arguments: [Any] {
        return [tokenAddress, tokenAmount, tokenNetwork]
    }
}

class PayInvoiceMethod: ContractMethod {
    private let invoiceId: BigUInt
    private let secretHash: Data

    init(invoiceId: BigUInt, secretHash: Data) {
        self.invoiceId = invoiceId
        self.secretHash = secretHash
        super.init()
    }

    override var methodSignature: String {
        return "payInvoice(uint256,bytes32)"
    }

    override var arguments: [Any] {
        return [invoiceId, secretHash]
    }
}

class ClaimMethod: ContractMethod {
    private let secret: BigUInt

    init(secret: BigUInt) {
        self.secret = secret
        super.init()
    }

    override var methodSignature: String {
        return "claim(uint256)"
    }

    override var arguments: [Any] {
        return [secret]
    }
}

class AtomicHolderTemplate: IAtomicSwap {
    private let host = "localhost"
    private let port = 64943
    
    private let ethereumKit: ISendEthereumAdapter
    private let lightningKit: ILightningInvoiceHandler
    
    var swap: Swap?
    var secret: [UInt8]
    var secretHash: String
    var id: String = "alice"
    
    init(ethereumKit: ISendEthereumAdapter, lightningKit: ILightningInvoiceHandler) {
        self.ethereumKit = ethereumKit
        self.lightningKit = lightningKit
        
        var randomBytes = [UInt8](repeating: 0, count: 32)
        _ = randomBytes.withUnsafeMutableBufferPointer { bufferPointer in
            SecRandomCopyBytes(kSecRandomDefault, 32, bufferPointer.baseAddress!)
        }
        
        secret = randomBytes
        let secretData = Data(hex: secret.toHexString())
        secretHash = Crypto.sha256(secretData).toHexString()
        
        print("[SWAP] secret holder secret hash: \(secretHash)")
    }
    
    func open() async throws {
        guard let swap = swap, let contractAddress = swap.secretHolder.asset.contractAddress else { return }
        
        print("[SWAP] Open in holder submarin")
                
        let invoice = try createInvoice(quantity: swap.secretHolder.quantity, contractAddress: contractAddress, keys: Data())
        
        //subscribe to invoice
        //settleInvoice
    }
    
    func commit() async throws {
        guard let swap = swap else { return }
    }
    
    func cancel() async throws {
        
    }
    
    func createInvoice(quantity: Int64, contractAddress: String, keys: Data) throws {
        guard let swap = swap else { return }
        
        let address = try Address(hex: contractAddress)
        let contractData = CreateInvoiceMethod(tokenAddress: address, tokenAmount: BigUInt(quantity), tokenNetwork: 5)
//        ethereumKit.call
    }
    
    private func signalSwapOpen(secret: String, invoice: String) async throws {
        let urlString = "http://\(host):\(port)/api/v1/swap"
        
        guard let swap = swap else {
            throw SwapError.swapNotExist
        }
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            throw SwapError.invalidURL
        }
        
        let encoder = JSONEncoder()
        
        let swapData = try encoder.encode(swap)
        let partyData = try encoder.encode(swap.secretHolder.isSecretHolder ? swap.secretHolder : swap.secretSeeker)
        
        let swapDict = try JSONSerialization.jsonObject(with: swapData, options: []) as? [String: Any]
        let partyDict = try JSONSerialization.jsonObject(with: partyData, options: []) as? [String: Any]
        let requestBody: [String: Any] = [
            "swap": swapDict as Any,
            "party": partyDict as Any,
            "invoice": invoice
        ]
                
        let request = try buildRequest(url: url, method: "PUT", userId: swap.secretHolder.isSecretHolder ? swap.secretHolder.id : swap.secretSeeker.id, body: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response: \(responseString)")
            print(responseString)
        } else {
            print("No response data")
            throw SwapError.emptyResponse
        }
    }
    
    private func buildRequest(url: URL, method: String, userId: String, body: [String: Any]) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method

        let creds = "\(userId):\(userId)"

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let base64Creds = Data(creds.utf8).base64EncodedString()
        let contentType = "application/json"
        let contentLength = request.httpBody?.count ?? 0

        request.addValue(contentType, forHTTPHeaderField: "Accept")
        request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        request.addValue(contentType, forHTTPHeaderField: "Accept-Encoding")
        request.addValue("Basic \(base64Creds)", forHTTPHeaderField: "Authorization")
        request.addValue("identity", forHTTPHeaderField: "Content-Encoding")
        request.addValue("\(contentLength)", forHTTPHeaderField: "Content-Length")
        
        return request
    }
    
//    func createInvoice(amount: BigInt, address: Address, privateKey: Data) -> Single<Any> {
//        let method = CreateInvoiceMethod(tokenAddress: address, tokenAmount: BigUInt(amount), tokenNetwork: 0)
//        let data = method.encodedABI()
//        return callSolidity(data: data, privateKey: privateKey)
//    }
//    
//    func payInvoice(invoiceId: BigInt, secretHash: Data, privateKey: Data, amount: BigInt) -> Single<Any> {
//        let method = PayInvoiceMethod(invoiceId: BigUInt(invoiceId), secretHash: secretHash)
//        let data = method.encodedABI()
//        return callSolidity(data: data, privateKey: privateKey, ethValue: amount)
//    }
//    
//    func settleInvoice(secret: BigInt, privateKey: Data) -> Single<Any> {
//        let method = ClaimMethod(secret: BigUInt(secret))
//        let data = method.encodedABI()
//        return callSolidity(data: data, privateKey: privateKey)
//    }
//    
//    private func callSolidity(data: Data, privateKey: Data, ethValue: BigInt? = nil) -> Single<Any> {
//        let transactionData = TransactionData(
//            to: try! Address(hex: ""),
//            value: BigUInt(ethValue!),
//            input: data
//        )
//        return ethereumKit.sendTransactionData(transactionData, privateKey: privateKey)
//            .flatMap { [weak self] transactionHash -> Single<TransactionReceipt> in
//                guard let self = self else { return Single.error(SwapError.invalidAmount) }
//                return self.evmKit.transactionReceipt(transactionHash: transactionHash)
//            }
//    }
}

