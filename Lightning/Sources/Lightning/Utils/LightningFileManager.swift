//
//  LightningFileManager.swift
//  
//
//  Created by Jurvis on 9/4/22.
//

import Foundation
import LightningDevKit

public struct LightningFileManager {
    let keysSeedPath = URL.keySeedDirectory
    let monitorPath = URL.channelMonitorsDirectory
    let managerPath = URL.channelManagerDirectory
    let scorerPath = URL.scorerDirectory
    let networkGraphPath = URL.networkGraphDirectory
    let paymentsPath = URL.paymentsDirectory
    
    public enum PersistenceError: Error {
        case cannotWrite
    }
    
    public static var hasPersistedChannelManager: Bool {
        FileManager.default.fileExists(atPath: URL.channelManagerDirectory.absoluteString)
    }
    
    public static func clearPaymentsDirectory() {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: URL.paymentsDirectory,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles)
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch  { print(error) }
    }
    
    public init() {}
    
    // MARK: - Public Read Interface
    public func getSerializedChannelManager() -> [UInt8]? {
        readChannelManager()
    }
    
    public func getSerializedChannelMonitors() -> [[UInt8]] {
        guard let monitorUrls = monitorUrls else { return [] }
        
        return monitorUrls.compactMap { url in
            readChannelMonitor(with: url)
        }
    }
    
    public func getSerializedNetworkGraph() -> [UInt8]? {
        readNetworkGraph()
    }
    
    public func getSerializedScorer() -> [UInt8]? {
        readScorer()
    }
    
    public func getKeysSeed() -> [UInt8]? {
        readKeysSeed()
    }
    
    public func getPayments() -> [LightningPayment] {
        guard let paymentsUrls = paymentsUrls else { return [] }
        
        return paymentsUrls.compactMap { url in
            readPayment(with: url)
        }
    }
    
    public var hasKeySeed: Bool {
        FileManager.default.fileExists(atPath: keysSeedPath.path)
    }
    
    public var hasChannelMaterialAndNetworkGraph: Bool {
        var isDir: ObjCBool = true
        return FileManager.default.fileExists(atPath: managerPath.path) &&
            FileManager.default.fileExists(atPath: monitorPath.path, isDirectory: &isDir) &&
            FileManager.default.fileExists(atPath: networkGraphPath.path)
    }
    
    // MARK: - Public Write Interface
    public func persistGraph(graph: [UInt8]) -> Result<Void, PersistenceError> {
        do {
            try Data(graph).write(to: networkGraphPath)
            return .success(())
        } catch {
            print("Cannot persist net graph: \(error)")
            return .failure(.cannotWrite)
        }
    }
    
    public func persistChannelManager(manager: [UInt8]) -> Result<Void, PersistenceError> {
        do {
            try Data(manager).write(to: managerPath, options: [.atomic, .completeFileProtection])
            return .success(())
        } catch {
            print("persistChannelManager FAILURE")
            return .failure(.cannotWrite)
        }
    }
    
    public func persistScorer(scorer: [UInt8]) -> Result<Void, PersistenceError> {
        do {
            try Data(scorer).write(to: scorerPath, options: [.atomic, .completeFileProtection])
            return .success(())
        } catch {
            print("persistChannelManager FAILURE")
            return .failure(.cannotWrite)
        }
    }
    
    public func persistKeySeed(keySeed: [UInt8]) -> Result<Void, PersistenceError> {
        do {
            try Data(keySeed).write(to: keysSeedPath, options: .completeFileProtection)
            return .success(())
        } catch {
            return .failure(.cannotWrite)
        }
    }
    
    public func persist(payment: LightningPayment) -> Result<Void, PersistenceError> {
        guard let pathToPersist = URL.pathForPersistingPayment(id: payment.paymentId) else {
            print("failed path to persist")
            return .failure(.cannotWrite)
        }
        
        let encoder = JSONEncoder()

        do {
            let data = try encoder.encode(payment)
            try data.write(to: pathToPersist, options: [.completeFileProtection])
            return .success(())
        } catch {
            print("failed path to persist error: \(error.localizedDescription)")
            return .failure(.cannotWrite)
        }
    }
    
    // MARK: - Private Read Functions
    private func readKeysSeed() -> [UInt8]? {
        do {
            let data = try Data(contentsOf: keysSeedPath)
            return Array(data)
        } catch {
            return nil
        }
    }
    
    private func readChannelManager() -> [UInt8]? {
        do {
            let data = try Data(contentsOf: managerPath)
            return Array(data)
        } catch {
            return nil
        }
    }
    
    private func readChannelMonitor(with channelURL: URL) -> [UInt8]? {
        do {
            let data = try Data(contentsOf: channelURL)
            if let monitor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? ChannelMonitor {
                return monitor.monitorBytes
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    private func readPayment(with paymentURL: URL) -> LightningPayment? {
        do {
            let data = try Data(contentsOf: paymentURL)
            let decoder = JSONDecoder()
            let payment = try decoder.decode(LightningPayment.self, from: data)
            return payment
        } catch {
            return nil
        }
    }
    
    private func readNetworkGraph() -> [UInt8]? {
        do {
            let data = try Data(contentsOf: networkGraphPath)
            return Array(data)
        } catch {
            return nil
        }
    }
    
    private func readScorer() -> [UInt8]? {
        do {
            let data = try Data(contentsOf: scorerPath)
            return Array(data)
        } catch {
            return nil
        }
    }
    
    // MARK: - Private Write Functions
    
    
    
    // MARK: - Computed Properties
    private var monitorUrls: [URL]? {
        do {
            let items = try FileManager.default.contentsOfDirectory(at: URL.channelMonitorsDirectory, includingPropertiesForKeys: nil)
            return items
        } catch {
            return nil
        }
    }
    
    private var paymentsUrls: [URL]? {
        do {
            let items = try FileManager.default.contentsOfDirectory(at: URL.paymentsDirectory, includingPropertiesForKeys: nil)
            return items
        } catch {
            return nil
        }
    }
}
