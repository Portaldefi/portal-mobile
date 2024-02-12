//
//  File.swift
//  
//
//  Created by Jurvis on 9/4/22.
//

import Foundation

public enum NodeError: Error {
    case connectPeer
    case disconectPeer
    case noChannelManager
    case networkGraphDataCorrupt
    case keyInterfaceFailure
    case keySeedNotFound
    case alreadyRunning
    case noChainManager
    case noChainMonitor
    case noRpcInterface
    case channelMaterialNotFound
    case noPayer
    case error(String)
    
    public enum Payments: Error {
        case invoice
        case routing
        case send
    }
    
    public enum Channels: Error {
        case apiMisuse(String)
        case router(String)
        case channelUnavailable(String)
        case feeRatesTooHigh(String)
        case incompatibleShutdownScript
        case unknown
        case channelManagerNotFound
        case fundingFailure
        case wrongLDKEvent
        case forceClosed
        case closedWithError
        case error(message: String)
        
        public var description: String {
            switch self {
            case .apiMisuse:
                return "Api misuse error"
            case .router:
                return "Router error"
            case .channelUnavailable:
                return "Channel unavaliable"
            case .feeRatesTooHigh:
                return "Fee rates too high"
            case .incompatibleShutdownScript:
                return "Incompatible shutdown script"
            case .channelManagerNotFound:
                return "Channel manager not found"
            case .fundingFailure:
                return "Funding failure"
            case .unknown:
                return "NodeError.Channels - Unknown error :/"
            case .wrongLDKEvent:
                return "Got wrong ldk event"
            case .error(let message):
                return message
            case .forceClosed:
                return "Force closed by counterparty"
            case .closedWithError:
                return "Closed with error"
            }
        }
    }
    
    public enum Invoice: Error {
        case notFound
        case invoicePaymentFailed
        case decodingError
    }
    
    public var description: String {
        switch self {
        case .connectPeer:
            return "Connect to peer error"
        case .noChannelManager:
            return "No channel manager error"
        case .keyInterfaceFailure:
            return "No key interface error"
        case .keySeedNotFound:
            return "Key seed not found error"
        case .alreadyRunning:
            return "Already running error"
        case .noChainManager:
            return "No chain manager error"
        case .noRpcInterface:
            return "No rpc interface error"
        case .channelMaterialNotFound:
            return "No channel material error"
        case .noPayer:
            return "No payer error"
        case .error(let string):
            return string
        case .disconectPeer:
            return "Failed disconnect from peer"
        case .noChainMonitor:
            return "ChainMonitor is not init"
        case .networkGraphDataCorrupt:
            return "Network graph data is corrupt"
        }
    }
}
