//
//  File.swift
//  
//
//  Created by farid on 2/10/23.
//

import Foundation
import Combine

enum BlockStreamMethods {
    case getChainTip,
         getBlockHashHex(UInt32),
         getBlock(String),
         getBlockBinary(String),
         getBlockHeader(String),
         getTransaction(String),
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
        case .postRawTx:
            return "/tx"
        }
    }
    
    var httpMethod: String {
        switch self {
        case .getChainTip, .getBlockHashHex, .getBlock, .getBlockBinary, .getBlockHeader, .getTransaction:
            return "GET"
        case .postRawTx:
            return "POST"
        }
    }
}


class BlockStreamChainManager {
    let rpcUrl: URL
    
    private var anchorBlock: BlockDetails?
    private var connectedBlocks = [BlockDetails]()
    
    private let monitoringTracker = MonitoringTracker()
    private var chainListeners = [ChainListener]()
    
    var blockchainMonitorPublisher: AnyPublisher<Void, Error> {
        Timer.publish(every: 15, on: RunLoop.main, in: .default)
            .autoconnect()
            .flatMap { [unowned self] _ in
                Future { promise in
                    Task {
                        try await self.reconcileChaintips()
                        promise(.success(()))
                    }
                }
            }
            .eraseToAnyPublisher()
    }
    
    init(rpcProtocol: RpcProtocol) throws {
        guard let rpcUrl = URL(string: "\(rpcProtocol.rawValue)://blockstream.info/testnet/api") else {
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
        return await self.monitoringTracker.startTracking()
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
            if let chainTip = String.init(data: data, encoding: String.Encoding.utf8) {
                return ["chainTip": UInt32(chainTip) as Any]
            }
            return [:]
        case .getBlockHashHex:
            if let blockHash = String.init(data: data, encoding: String.Encoding.utf8) {
                return ["blockHash": blockHash as Any]
            }
            return [:]
        case .getBlock:
            let response = try JSONSerialization.jsonObject(with: data, options: .topLevelDictionaryAssumed)
            let responseDictionary = response as! [String: Any]
            if let responseError = responseDictionary["error"] as? [String: Any] {
                let errorDetails = RPCErrorDetails(message: responseError["message"] as! String, code: responseError["code"] as! Int64)
                print("error details: \(errorDetails)")
                throw RpcError.errorResponse(errorDetails)
            }
            return responseDictionary
        case .getBlockBinary:
            return ["blockBinary": data.toHexString() as Any]
        case .getBlockHeader:
            let response = try JSONSerialization.jsonObject(with: data, options: .topLevelDictionaryAssumed)
            let responseDictionary = response as! [String: Any]
            if let responseError = responseDictionary["error"] as? [String: Any] {
                let errorDetails = RPCErrorDetails(message: responseError["message"] as! String, code: responseError["code"] as! Int64)
                print("error details: \(errorDetails)")
                throw RpcError.errorResponse(errorDetails)
            }
            return responseDictionary
        case .getTransaction:
            if let txHex = String.init(data: data, encoding: String.Encoding.utf8) {
                print(txHex)
                return ["txHex": txHex as Any]
            }
            return [:]
        case .postRawTx:
            if let txID = String.init(data: data, encoding: String.Encoding.utf8) {
                print("posted txID: \(txID)")
                return ["txID": txID as Any]
            }
            return [:]
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

// MARK: RPC Calls
extension BlockStreamChainManager {
    func getChaintipHeight() async throws -> UInt32 {
        let response = try await self.callRpcMethod(method: .getChainTip)
        if let result = response["chainTip"] as? UInt32 {
            return result
        }
        throw ChainManagerError.unknownAnchorBlock
    }
    
    func getChaintipHash() async throws -> [UInt8] {
        let blockHashHex = try await self.getChaintipHashHex()
        return hexStringToBytes(hexString: blockHashHex)!
    }
    
    func getBlockHashHex(height: UInt32) async throws -> String {
        let response = try await self.callRpcMethod(method: .getBlockHashHex(height))
        let result = response["blockHash"] as! String
        return result
    }
    
    func getBlock(hash: String) async throws -> BlockDetails {
        let response = try await self.callRpcMethod(method: .getBlock(hash))
        return try JSONDecoder().decode(BlockDetails.self, from: JSONSerialization.data(withJSONObject: response))
    }
    
    func getBlockBinary(hash: String) async throws -> [UInt8] {
        let response = try await self.callRpcMethod(method: .getBlockBinary(hash))
        let result = response["blockBinary"] as! String
        let blockData = hexStringToBytes(hexString: result)!
        return blockData
    }
    
    func getChaintipHashHex() async throws -> String {
        let height = try await self.getChaintipHeight()
        let hash = try await self.getBlockHashHex(height: height)
        return hash
    }
    
    func getBlockHeader(hash: String) async throws -> [UInt8] {
        let response = try await self.callRpcMethod(method: .getBlockHeader(hash))
        let result = response["result"] as! String
        let blockHeader = hexStringToBytes(hexString: result)!
        assert(blockHeader.count == 80)
        return blockHeader
    }
    
    public func getTransaction(with hash: String) async throws -> [UInt8] {
        let response = try await self.callRpcMethod(method: .getTransaction(hash))
        let txHex = response["result"] as! String
        let transaction = hexStringToBytes(hexString: txHex)!
        return transaction
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
    
    enum ChainManagerError: Error {
        case invalidUrlString
        case unknownAnchorBlock
        case unableToConnectBlock(blockHeight: UInt32)
    }
}


// MARK: Common ChainManager Functions
extension BlockStreamChainManager: RpcChainManager {
    func submitTransaction(transaction: [UInt8]) async throws -> String {
        let txHex = bytesToHexString(bytes: transaction)
        let response = try? await self.callRpcMethod(method: .postRawTx(txHex))
        // returns the txid
        let result = response?["txID"] as? String
        return result ?? "unknown tx id"
    }
}

fileprivate func hexStringToBytes(hexString: String) -> [UInt8]? {
    let hexStr = hexString.dropFirst(hexString.hasPrefix("0x") ? 2 : 0)

    guard hexStr.count % 2 == 0 else {
        return nil
    }

    var newData = [UInt8]()

    var indexIsEven = true
    for i in hexStr.indices {
        if indexIsEven {
            let byteRange = i...hexStr.index(after: i)
            guard let byte = UInt8(hexStr[byteRange], radix: 16) else {
                return nil
            }
            newData.append(byte)
        }
        indexIsEven.toggle()
    }
    return newData
}

fileprivate func bytesToHexString(bytes: [UInt8]) -> String {
    let format = "%02hhx" // "%02hhX" (uppercase)
    return bytes.map {
        String(format: format, $0)
    }
    .joined()
}
