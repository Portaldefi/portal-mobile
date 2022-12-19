//
//  EthereumKitManager.swift
//  Portal
//
//  Created by Farid on 19.07.2021.
//

import Foundation
import EvmKit
import HdWalletKit
import Combine
import RxSwift

import RxSwift
import EvmKit
import HdWalletKit

class EthereumKitManager {
    static let shared = EthereumKitManager()

    private let keyWords = "mnemonic_words"
    private let keyAddress = "address"

    var evmKit: Kit!
    var signer: Signer?
    var adapter: EthereumAdapter!

    init() {
        try? initKit(words: EthereumConfiguration.shared.defaultsWords.split(separator: " ").map(String.init))
    }

    private func initKit(address: Address, configuration: EthereumConfiguration, signer: Signer?) throws {
        let evmKit = try Kit.instance(
                address: address,
                chain: configuration.chain,
                rpcSource: configuration.rpcSource,
                transactionSource: configuration.transactionSource,
                walletId: "walletId",
                minLogLevel: configuration.minLogLevel
        )

        adapter = EthereumAdapter(evmKit: evmKit, signer: signer)

        self.evmKit = evmKit
        self.signer = signer

        evmKit.start()
    }


    private func initKit(words: [String]) throws {
        let configuration = EthereumConfiguration.shared

        guard let seed = Mnemonic.seed(mnemonic: words) else {
            throw LoginError.seedGenerationFailed
        }

        let signer = try Signer.instance(seed: seed, chain: configuration.chain)

        try initKit(
                address: try Signer.address(seed: seed, chain: configuration.chain),
                configuration: configuration,
                signer: signer
        )
    }

    private func initKit(address: Address) throws {
        let configuration = EthereumConfiguration.shared

        try initKit(address: address, configuration: configuration, signer: nil)
    }

    private var savedWords: [String]? {
        guard let wordsString = UserDefaults.standard.value(forKey: keyWords) as? String else {
            return nil
        }

        return wordsString.split(separator: " ").map(String.init)
    }

    private var savedAddress: Address? {
        guard let addressString = UserDefaults.standard.value(forKey: keyAddress) as? String else {
            return nil
        }

        return try? Address(hex: addressString)
    }

    private func save(words: [String]) {
        UserDefaults.standard.set(words.joined(separator: " "), forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

    private func save(address: String) {
        UserDefaults.standard.set(address, forKey: keyAddress)
        UserDefaults.standard.synchronize()
    }

    private func clearStorage() {
        UserDefaults.standard.removeObject(forKey: keyWords)
        UserDefaults.standard.removeObject(forKey: keyAddress)
        UserDefaults.standard.synchronize()
    }

}

extension EthereumKitManager {
    func login(words: [String]) throws {
        try Kit.clear(exceptFor: ["walletId"])

        save(words: words)
        try initKit(words: words)
    }

    func watch(address: Address) throws {
        try Kit.clear(exceptFor: ["walletId"])

        save(address: address.hex)
        try initKit(address: address)
    }

    func logout() {
        clearStorage()

        signer = nil
        evmKit = nil
        adapter = nil
    }
}

extension EthereumKitManager {
    enum LoginError: Error {
        case seedGenerationFailed
    }
}

import HsToolKit

class EthereumConfiguration {
    static let shared = EthereumConfiguration()

    let minLogLevel: Logger.Level = .error

    let chain: Chain = .ethereum
    let rpcSource: RpcSource = .ethereumInfuraWebsocket(projectId: "2a1306f1d12f4c109a4d4fb9be46b02e", projectSecret: "fc479a9290b64a84a15fa6544a130218")
    let transactionSource: TransactionSource = .ethereumEtherscan(apiKey: "GKNHXT22ED7PRVCKZATFZQD1YI7FK9AAYE")

    let defaultsWords = "point head pencil differ reopen damp wink minute improve toward during term"
    let defaultsWatchAddress = "0xDc3EAB13c26C0cA48843c16d1B27Ff8760515016"
}

