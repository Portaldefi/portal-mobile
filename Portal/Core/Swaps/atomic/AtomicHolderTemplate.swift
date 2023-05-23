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
        print("[SWAP] Open in holder")
                
        guard let swap = swap, let holderAddressHex = swap.secretHolder.asset.contractAddress else {
            throw SwapError.missingData
        }
        
//        try await signalSwapOpen(swap: swap)

        let tokenAddress = try Address(hex: holderAddressHex)
        let quantity = BigUInt(swap.secretHolder.quantity)
        
        let createInvoiceTransaction = try await createInvoice(tokenAddress: tokenAddress, quantity: quantity, tokenNetwork: 0)
        
        print("[SWAP] CreateInvoice tx id: \(createInvoiceTransaction.transaction.hash.toHexString())")
        
        let receipt = try await waitForTransactionReceipt(transactionHash: createInvoiceTransaction.transaction.hash)
        let invoiceId = parseInvoiceId(receipt: receipt)
        
        print(invoiceId.description)
        print("[SWAP] Invoice id: \(invoiceId.description) is created for holder")
        
//        let updatedSwap = updateState(swap: swap, state: ["goerli" : invoiceId.description])
//
//        print("[SWAP] Sending updated swap: \(updatedSwap) to server")
//
//        try await signalSwapOpen(swap: swap)
        
        print("[SWAP] Updated state sent")
        
        //subscribe to invoice
        //settleInvoice
    }
    
    func updateState(swap: Swap, state: [String : [String: InvoiceCodable]]) -> Swap {
        let secretHolder = swap.secretHolder
        
        let secretHolderUpdated = Party(
            id: secretHolder.id,
            swap: secretHolder.swap,
            asset: secretHolder.asset,
            network: secretHolder.network,
            quantity: secretHolder.quantity,
            state: state,
            isSecretSeeker: secretHolder.isSecretSeeker,
            isSecretHolder: secretHolder.isSecretHolder
        )
        
        return Swap(
            id: swap.id,
            secretHash: swap.secretHash,
            secretHolder: secretHolderUpdated,
            secretSeeker: swap.secretSeeker,
            status: swap.status
        )
    }
    
    func waitForTransactionReceipt(transactionHash: Data, pollingInterval: TimeInterval = 3) async throws -> RpcTransactionReceipt {
        while true {
            do {
                print("[SWAP] waiting for tx receipt...")
                let receipt = try await fetchTxReceipt(hash: transactionHash)
                return receipt
            } catch {
                print(error)
            }
            try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1000_000_000))
        }
    }
    
//    func waitForTransactionReceipt(evmKit: ISendEthereumAdapter, transactionHash: Data, pollingInterval: TimeInterval = 5) async throws -> RpcTransactionReceipt {
//        while true {
//            let receipt = try await evmKit.transactionReceipt(hash: transactionHash)
//            print("receipt: \(receipt)")
//            
//            
//            await Task.sleep(UInt64(pollingInterval * 1000_000_000))
//        }
//    }
    
    func commit() async throws {
        guard let swap = swap else { return }
        
        //Alice pays lightning invoice
        
    }
    
    func cancel() async throws {
        
    }
    
    func fetchTxReceipt(hash: Data) async throws -> RpcTransactionReceipt {
        try await ethereumKit.transactionReceipt(hash: hash)
    }
    
    func parseInvoiceId(receipt: RpcTransactionReceipt) -> BigUInt {
        let hex = receipt.logs[0].data.subdata(in: 1..<33)
        return BigUInt(hex)
    }
    
    func createInvoice(tokenAddress: Address, quantity: BigUInt, tokenNetwork: BigUInt) async throws -> FullTransaction {
        let contractData = CreateInvoiceMethod(
            tokenAddress: tokenAddress,
            tokenAmount: quantity,
            tokenNetwork: tokenNetwork
        )
        
        let encodedContractData = contractData.encodedABI()
        
        let contractAddress = try Address(hex: "0xe2f24575862280cf6574db5b9b3f8fe0be84dc62")
        let kit = Container.ethereumKitManager()
        let feerateKit = Container.feeRateProvider()
        let gasPriceInt = try await feerateKit.ethereumGasPrice()
        let gasPrice: GasPrice = .legacy(gasPrice: gasPriceInt)
                
        let transactionData = TransactionData(to: contractAddress, value: 0, input: encodedContractData)
        
        guard let ethKit = kit.ethereumKit else { throw SwapError.missingEthKit }
        
        let estimatedGas = try await ethKit.fetchEstimateGas(transactionData: transactionData, gasPrice: gasPrice)

        return try await ethereumKit.send(transactionData: transactionData, gasLimit: estimatedGas, gasPrice: gasPrice)
    }
    
    private func signalSwapOpen(swap: Swap) async throws {
        let urlString = "http://\(host):\(port)/api/v1/swap"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            throw SwapError.invalidURL
        }
        
        let encoder = JSONEncoder()
        
        let swapData = try encoder.encode(swap)
//        let partyData = try encoder.encode(swap.secretHolder.isSecretHolder ? swap.secretHolder : swap.secretSeeker)
        
        let swapDict = try JSONSerialization.jsonObject(with: swapData, options: []) as? [String: Any]
//        let partyDict = try JSONSerialization.jsonObject(with: partyData, options: []) as? [String: Any]
        let requestBody: [String: Any] = [
            "swap": swapDict as Any,
//            "party": partyDict as Any
        ]
                
        let request = try buildRequest(url: url, method: "PUT", userId: swap.secretHolder.isSecretHolder ? swap.secretHolder.id : swap.secretSeeker.id, body: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response: \(responseString)")
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

