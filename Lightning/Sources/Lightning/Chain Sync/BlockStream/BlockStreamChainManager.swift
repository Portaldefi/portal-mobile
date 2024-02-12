//
//  File.swift
//
//
//  Created by farid on 2/10/23.
//

import Foundation
import Combine
import CryptoSwift
import LightningDevKit

enum BlockStreamMethods {
    case getChainTip,
         getBlockHashHex(UInt32),
         getBlock(String),
         getBlockBinary(String),
         getBlockHeader(String),
         getTransaction(String),
         getRawTransaction(String),
         getMerkleProof(String),
         getTxStatus(String),
         getTxById(String),
         outSpent(txId: String, index: UInt16),
         postRawTx(String)
    
    var path: String {
        switch self {
        case .getChainTip:
            return "/blocks/tip/height"
        case .getBlockHashHex(let height):
            return "/block-height/\(height)"
        case .getBlock(let hash):
            return "/block/\(hash)"
        case .getBlockBinary(let hash):
            return "/block/\(hash)/raw"
        case .getBlockHeader(let hash):
            return "/block/\(hash)/header"
        case .getTransaction(let hash):
            return "/tx/\(hash)/hex"
        case .getTxById(let id):
            return "/tx/\(id)"
        case .getRawTransaction(let id):
            return "/tx/\(id)/raw"
        case .getMerkleProof(let id):
            return "/tx/\(id)/merkle-proof"
        case .outSpent(let txId, let index):
            return "/tx/\(txId)/outspend/\(index)"
        case .postRawTx:
            return "/tx"
        case .getTxStatus(let txId):
            return "/tx/\(txId)/status"
        }
    }
    
    var httpMethod: String {
        switch self {
        case .postRawTx:
            return "POST"
        default:
            return "GET"
        }
    }
}


class BlockStreamChainManager {
    let rpcUrl: URL
    
    private var anchorBlock: BlockDetails?
    private var connectedBlocks = [BlockDetails]()
    
    private let monitoringTracker = MonitoringTracker()
    private var chainListeners = [ChainListener]()
    private var chainFilter: ChainFilter?
    
    private var subscriptions = Set<AnyCancellable>()
    
    var blockchainMonitorPublisher: AnyPublisher<Void, Error> {
        Timer.publish(every: 15, on: RunLoop.main, in: .default)
            .autoconnect()
            .flatMap { _ in
                Future { promise in
                    promise(.success(()))
                }
            }
            .eraseToAnyPublisher()
    }
    
    init(network: Network) throws {
        let baseUrlString: String
        
        switch network {
        case .Bitcoin:
            baseUrlString = "https://blockstream.info/api"
        case .Regtest:
            baseUrlString = "http:/localhost:3002"
        case .Testnet:
            baseUrlString = "https://blockstream.info/testnet/api"
        default:
            fatalError("Network not supported")
        }
        
        guard let rpcUrl = URL(string: baseUrlString) else {
            throw ChainManagerError.invalidUrlString
        }
        
        self.rpcUrl = rpcUrl
    }
    
    func registerListener(_ listener: ChainListener) {
        self.chainListeners.append(listener)
    }
    
    /// This method takes in an `anchorHeight` and provides us with a way to make the requisite calls needed to Blockstream in order to
    /// let `Listener`s know about blocks to connect.
    func preloadMonitor(anchorHeight: MonitorAnchor) async throws {
        // If tracker is already preloaded, don't try again.
        guard !(await self.monitoringTracker.preload()) else {
            return
        }
        
        var lastTrustedBlockHeight: UInt32
        let chaintipHeight = try await self.getChaintipHeight()
        switch anchorHeight {
        case .genesis:
            lastTrustedBlockHeight = 0
        case .block(let height):
            lastTrustedBlockHeight = height
        case .chaintip:
            lastTrustedBlockHeight = chaintipHeight
        }
        
        do {
            let anchorBlockHash = try await self.getBlockHashHex(height: lastTrustedBlockHeight)
            let anchorBlock = try await self.getBlock(hash: anchorBlockHash)
            connectedBlocks.append(anchorBlock)
        } catch {
            throw ChainManagerError.unknownAnchorBlock
        }
        
        if lastTrustedBlockHeight != chaintipHeight {
            do {
                try await self.connectBlocks(from: lastTrustedBlockHeight + 1, to: chaintipHeight)
            } catch ChainManagerError.unableToConnectBlock(let blockHeight) {
                print("Unable to connect to block at \(blockHeight). Stopping preload...")
            }
        }
    }
    
    func isMonitoring() async -> Bool {
        await self.monitoringTracker.startTracking()
    }
}

// MARK: Helper Functions
extension BlockStreamChainManager {
    // Trigger a check of what's the latest
    private func reconcileChaintips() async throws {
        let currentChaintipHeight = try await self.getChaintipHeight()
        let currentChaintipHash = try await self.getChaintipHashHex()

        // Check if we area already at chain tip.
        guard let knownChaintip = self.connectedBlocks.last,
           knownChaintip.height != currentChaintipHeight && knownChaintip.hash != currentChaintipHash else {
            return
        }

        // create an array of the new blocks
        var addedBlocks = [BlockDetails]()
        if knownChaintip.height < currentChaintipHeight {
           // without this precondition, the range won't even work to begin with
           for addedBlockHeight in (knownChaintip.height + 1)...currentChaintipHeight {
               let addedBlockHash = try await self.getBlockHashHex(height: addedBlockHeight)
               let addedBlock = try await self.getBlock(hash: addedBlockHash)
               addedBlocks.append(addedBlock)
           }
        }

        while addedBlocks.isEmpty || addedBlocks.first!.previousblockhash != self.connectedBlocks.last!.hash {
           // we must keep popping until it matches
           let trimmingCandidate = self.connectedBlocks.last!
           if trimmingCandidate.height > currentChaintipHeight {
               // we can disconnect this block without prejudice
               _ = try await self.disconnectBlock()
               continue
           }
           let reorgedBlockHash = try await self.getBlockHashHex(height: trimmingCandidate.height)
           if reorgedBlockHash == trimmingCandidate.hash {
               // this block matches the one we already have
               break
           }
           let reorgedBlock = try await self.getBlock(hash: reorgedBlockHash)
           _ = try await self.disconnectBlock()
           addedBlocks.insert(reorgedBlock, at: 0)
        }

        for addedBlock in addedBlocks {
           try await self.connectBlock(block: addedBlock)
        }
    }
    
    private func callRpcMethod(method: BlockStreamMethods) async throws -> [String: Any] {
        let apiUrl = rpcUrl.appendingPathComponent(method.path)
        var request = URLRequest(url: apiUrl)
        request.httpMethod = method.httpMethod
        
        if case .postRawTx(let transaction) = method {
            request.httpBody = transaction.data(using: .utf8)
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
                
        switch method {
        case .getChainTip:
            guard let chainTip = data.utf8String() else {
                throw BlockStreamApiError.getChainTip
            }
            return ["chainTip": UInt32(chainTip) as Any]
        case .getBlockHashHex:
            guard let blockHash = data.utf8String() else {
                throw BlockStreamApiError.getBlockHashHex
            }
            return ["blockHash": blockHash as Any]
        case .getBlockBinary:
            return ["blockBinary": data.toHexString() as Any]
        case .getBlockHeader:
            guard let headerHash = data.utf8String() else {
                throw BlockStreamApiError.getBlockHeader
            }
            return ["result": headerHash as Any]
        case .getTransaction:
            guard let txHex = data.utf8String() else {
                throw BlockStreamApiError.getTransaction
            }
            return ["txHex": txHex as Any]
        case .getRawTransaction:
            return ["rawTx": data]
        case .postRawTx:
            guard let txID = data.utf8String() else {
                throw BlockStreamApiError.postRawTx
            }
            print("posted txID: \(txID)")
            return ["txID": txID as Any]
        case .getBlock:
            guard let json = try JSONSerialization.jsonObject(with: data, options: .topLevelDictionaryAssumed) as? [String: Any] else {
                throw BlockStreamApiError.getBlock
            }
            
            if
                let responseError = json["error"] as? [String: Any],
                let message = responseError["message"] as? String,
                let code = responseError["code"] as? Int64
            {
                
                let errorDetails = RPCErrorDetails(message: message, code: code)
                
                print("error details: \(errorDetails)")
                throw RpcError.errorResponse(errorDetails)
            }
            
            return json
        case .getTxById, .getMerkleProof, .outSpent, .getTxStatus:
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                throw BlockStreamApiError.unwrapJson
            }
            
            if
                let responseError = json["error"] as? [String: Any],
                let message = responseError["message"] as? String,
                let code = responseError["code"] as? Int64
            {
                
                let errorDetails = RPCErrorDetails(message: message, code: code)
                
                print("error details: \(errorDetails)")
                throw RpcError.errorResponse(errorDetails)
            }
            
            return json
        }
    }
    
    private func connectBlocks(from: UInt32, to: UInt32) async throws {
        for currentBlockHeight in from...to {
            do {
                let currentBlockHash = try await self.getBlockHashHex(height: currentBlockHeight)
                let currentBlock = try await self.getBlock(hash: currentBlockHash)
                try await self.connectBlock(block: currentBlock)
            } catch {
                throw ChainManagerError.unableToConnectBlock(blockHeight: currentBlockHeight)
            }
        }
    }
    
    private func connectBlock(block: BlockDetails) async throws {
        if self.connectedBlocks.count > 0 {
            let lastConnectionHeight = self.connectedBlocks.last!.height
            if lastConnectionHeight + 1 != block.height {
                // trying to connect block out of order
                throw ChainObservationError.nonSequentialBlockConnection
            }
            let lastBlockHash = self.connectedBlocks.last!.hash
            if block.previousblockhash != lastBlockHash {
                // this should in principle never occur, as the caller should check and reconcile beforehand
                throw ChainObservationError.unhandledReorganization
            }
        }

        print("connecting block at \(block.height) with hex: \(block.hash)")

        if !self.chainListeners.isEmpty {
            let binary = try await self.getBlockBinary(hash: block.hash)
            for listener in self.chainListeners {
                listener.blockConnected(block: binary, height: UInt32(block.height))
            }
        }

        self.connectedBlocks.append(block)
    }
    
    private func disconnectBlock() async throws -> BlockDetails {
        if self.connectedBlocks.count <= 1 {
            // we're about to disconnect the anchor block, which we can't
            throw ChainObservationError.excessiveReorganization
        }

        let poppedBlock = self.connectedBlocks.popLast()!

        print("disconnecting block \(poppedBlock.height) with hex: \(poppedBlock.hash)")

        if self.chainListeners.count > 0 {
            let blockHeader = try await self.getBlockHeader(hash: poppedBlock.hash)
            for listener in self.chainListeners {
                listener.blockDisconnected(header: blockHeader, height: UInt32(poppedBlock.height))
            }
        }

        return poppedBlock
    }
}

enum BlockStreamApiError: Error {
    case getChainTip,
         hexStringToBytesDecodeFailed,
         getBlockHashHex,
         getBlock,
         getBlockHeader,
         getChaintipHeight,
         getTransaction,
         getRawTransaction,
         getTxById,
         getMerkleProof,
         postRawTx,
         getTransactionWithHash,
         unwrapJson
}

// MARK: RPC Calls
extension BlockStreamChainManager {
    func getChaintipHeight() async throws -> UInt32 {
        let response = try await self.callRpcMethod(method: .getChainTip)
        
        guard let result = response["chainTip"] as? UInt32 else {
            throw BlockStreamApiError.getChaintipHeight
        }
        
        return result
    }
    
    func getChaintipHash() async throws -> [UInt8] {
        let blockHashHex = try await self.getChaintipHashHex()
        
        guard let bytesArraay = Utils.hexStringToBytes(hexString: blockHashHex) else {
            throw BlockStreamApiError.hexStringToBytesDecodeFailed
        }
        return bytesArraay
    }
    
    func getBlockHashHex(height: UInt32) async throws -> String {
        let response = try await self.callRpcMethod(method: .getBlockHashHex(height))
        
        guard let result = response["blockHash"] as? String else {
            throw BlockStreamApiError.getBlockHashHex
        }
        
        return result
    }
    
    func getBlock(hash: String) async throws -> BlockDetails {
        let response = try await self.callRpcMethod(method: .getBlock(hash))
        return try JSONDecoder().decode(BlockDetails.self, from: JSONSerialization.data(withJSONObject: response))
    }
    
    func getBlockBinary(hash: String) async throws -> [UInt8] {
        let response = try await self.callRpcMethod(method: .getBlockBinary(hash))
        
        guard
            let result = response["blockBinary"] as? String,
            let blockData = Utils.hexStringToBytes(hexString: result)
        else {
            throw BlockStreamApiError.hexStringToBytesDecodeFailed
        }
        
        return blockData
    }
    
    func getChaintipHashHex() async throws -> String {
        let height = try await self.getChaintipHeight()
        return try await self.getBlockHashHex(height: height)
    }
        
    public func getTransaction(with hash: String) async throws -> [UInt8] {
        let response = try await self.callRpcMethod(method: .getTransaction(hash))
        
        guard
            let txHex = response["txHex"] as? String,
            let transaction = Utils.hexStringToBytes(hexString: txHex)
        else {
            throw BlockStreamApiError.getTransactionWithHash
        }
        
        return transaction
    }
}

public struct OutSpent: Codable {
    let spent: Bool
    let txid: String?
}

extension Data {
    func utf8String() -> String? {
        String.init(data: self, encoding: String.Encoding.utf8)
    }
}

// MARK: Supporting Data Structures
extension BlockStreamChainManager {
    struct BlockDetails: Decodable {
        let hash: String
        let version: Int64
        let mediantime: Int64
        let nonce: Int64
        let nTx: Int64
        let time: Int64
        let weight: Int64
        let merkleroot: String
        let size: Int64
        let height: UInt32
        let difficulty: Double
        let previousblockhash: String?
        let bits: Int64
        
        enum CodingKeys: String, CodingKey {
            case hash = "id"
            case version
            case mediantime
            case nonce
            case nTx = "tx_count"
            case time = "timestamp"
            case weight
            case merkleroot = "merkle_root"
            case size
            case height
            case difficulty
            case previousblockhash
            case bits
        }
    }
    
    enum RpcProtocol: String {
        case http = "http"
        case https = "https"
    }
    func getTxMerkleProof(txId: String) async throws -> Int32 {
        let response = try await self.callRpcMethod(method: .getMerkleProof(txId))
        
        guard let pos = response["pos"] as? Int32 else {
            throw BlockStreamApiError.getMerkleProof
        }
        
        return pos
    }
    
    enum ChainManagerError: Error {
        case invalidUrlString
        case unknownAnchorBlock
        case unableToConnectBlock(blockHeight: UInt32)
    }
}


// MARK: Common ChainManager Functions
extension BlockStreamChainManager: RpcChainManager {
    func getTxStatus(txId: String) async throws -> [String : Any] {
        try await self.callRpcMethod(method: .getTxStatus(txId))
    }
    
    func getTxOutspent(txId: String, index: UInt16) async throws -> OutSpent {
        let response = try await self.callRpcMethod(method: .outSpent(txId: txId, index: index))
        
        var outoutSpent = false
        
        if let spent = response["spent"] as? Bool {
            outoutSpent = spent
        } else {
            print("")
        }
        
        return OutSpent(spent: outoutSpent, txid: response["txid"] as? String)
    }
    
    func getRawTransaction(txId: String) async throws -> Data {
        let data = try await self.callRpcMethod(method: .getRawTransaction(txId))
        
        guard let rawTx = data["rawTx"] as? Data else {
            throw BlockStreamApiError.getRawTransaction
        }
        
        return rawTx
    }
    
    func getBlockHashHex(height: Int64) async throws -> String {
        guard let blockHeight = UInt32(exactly: height) else {
            throw BlockStreamApiError.getBlockHashHex
        }
        
        let response = try await self.callRpcMethod(method: .getBlockHashHex(blockHeight))
        
        guard let blockHash = response["blockHash"] as? String else {
            throw BlockStreamApiError.getBlockHashHex
        }
        
        return blockHash
    }
    
    func decodeRawTransaction(tx: [UInt8]) async throws -> [String : Any] {
        [:]
    }
    
    func mineBlocks(number: Int, coinbaseDestinationAddress: String) async throws -> [String] {
        []
    }
    
    func scanTxOutSet(descriptor: String) async throws -> [String : Any] {
        [:]
    }
    
    func getDescriptorInfo(descriptor: String) async throws -> String {
        String()
    }
    
    func decodeScript(script: [UInt8]) async throws -> [String : Any] {
        let scriptHexString = script.toHexString()
        
        // Extract the script hash (skip the first 2 characters '00' and the next 2 characters '20' which represents the length)
        let scriptHashHexString = String(scriptHexString.dropFirst(4))
        let scriptHash = Data(hex: scriptHashHexString)
    
        let segwitCoder = SegwitAddress()
        let decoded = try segwitCoder.encode(hrp: "tb", version: 0, program: scriptHash)
        return ["address": decoded]
    }
    
    func submitTransaction(transaction: [UInt8]) async throws -> String {
        let txHex = Utils.bytesToHexString(bytes: transaction)
        let response = try? await self.callRpcMethod(method: .postRawTx(txHex))
        // returns the txid
        let result = response?["txID"] as? String
        return result ?? "unknown tx id"
    }
    
    func getTransactionWithId(id: String) async throws -> [String: Any] {
        try await self.callRpcMethod(method: .getTxById(id))
    }
    
    func getBlockHeader(hash: String) async throws -> [UInt8] {
        let response = try await self.callRpcMethod(method: .getBlockHeader(hash))
        
        guard
            let result = response["result"] as? String,
            let blockHeader = Utils.hexStringToBytes(hexString: result)
        else {
            throw BlockStreamApiError.getBlockHeader
        }
        
        assert(blockHeader.count == 80)
        return blockHeader
    }
}
