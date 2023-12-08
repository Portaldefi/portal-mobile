//
//  EvmLightningSwapPlaynetSample.swift
//  PortalTests
//
//  Created by farid on 01.12.2023.
//

import Foundation
import Promises
import PortalSwapSDK

class EvmLightningSwapPlaynetSample {
    private let BTC_WALLET_NAME = "PLAYNET_LDK_INTEGRATION_TEST_WALLET"
    private let MOCK_OUTPUT_SCRIPT: [UInt8] = [0, 1, 0]
    
    var alice: SwapParticipant!
    var bob: SwapParticipant!
    
    let rpcInterface: RegtestBlockchainManager
    
    init() async throws {
        rpcInterface = try RegtestBlockchainManager(
            rpcProtocol: .http,
            rpcDomain: "localhost",
            rpcPort: 18443,
            rpcUsername: "lnd",
            rpcPassword: "lnd"
        )
        
        try await addFundsToTestWalletIfNeeded(rpcInterface: rpcInterface)
        
        alice = try await SwapParticipant(
            id: "alice_\(UUID().uuidString)",
            ethPrivKey: "3b8c40c0c97ff9448efcb0a5b9d208eda490cead042f49b98668710004ae864d",
            rpcInterface: rpcInterface
        )
                
        bob = try await SwapParticipant(
            id: "bob_\(UUID().uuidString)",
            ethPrivKey: "76c2f07d925ebc522195055f0df6624e877ac6c03f629e6174cf9bb34b59a264",
            rpcInterface: rpcInterface
        )
    }
    
    private func addFundsToTestWalletIfNeeded(rpcInterface: RegtestBlockchainManager) async throws {
        let fakeAddress = try await self.getMockAddress(rpcInterface: rpcInterface)
        let _ = try await rpcInterface.mineBlocks(number: 1, coinbaseDestinationAddress: fakeAddress)
        
        let availableWallets = try await rpcInterface.listAvailableWallets()
        let walletNames = (availableWallets["wallets"] as! [[String: Any]]).map { dictionary -> String in
            dictionary["name"] as! String
        }

        if !walletNames.contains(BTC_WALLET_NAME) {
            // if a wallet is already loaded, this will load it also
            print("Attempt to create wallet with name: \(BTC_WALLET_NAME))")
            let newWallet = try await rpcInterface.createWallet(name: BTC_WALLET_NAME)
            print("Created wallet with name: \(String(describing: newWallet["name"]))")
        }

        let loadedWallets = try await rpcInterface.listLoadedWallets()
        let isPlaynetWalletLoaded = loadedWallets.contains(BTC_WALLET_NAME)
        for currentWalletName in loadedWallets {
            if currentWalletName == BTC_WALLET_NAME {
                continue
            }
            let unloadedWallet = try await rpcInterface.unloadWallet(name: currentWalletName)
            print("Wallet named: \(String(describing: unloadedWallet["name"])) is unloaded")
        }

        if !isPlaynetWalletLoaded {
            print("Loading wallet: \(BTC_WALLET_NAME)")
            let _ = try await rpcInterface.loadWallet(name: BTC_WALLET_NAME)
        }
        
        let walletBalance = try await rpcInterface.getWalletBalance()

        if walletBalance < 1 {
            print("Wallet balance of \(walletBalance) too low, mining some blocks")
            let address = try await rpcInterface.generateAddress()
            let _ = try await rpcInterface.mineBlocks(number: 1, coinbaseDestinationAddress: address)

            let fakeAddress = try await self.getMockAddress(rpcInterface: rpcInterface)
            let _ = try await rpcInterface.mineBlocks(number: 50, coinbaseDestinationAddress: fakeAddress)

            let updatedWalletBalance = try await rpcInterface.getWalletBalance()
            let balanceIncrease = updatedWalletBalance - walletBalance
            print("New wallet balance: \(updatedWalletBalance) (increase of \(balanceIncrease))")
        }
    }
    
    private func getMockAddress(rpcInterface: RegtestBlockchainManager) async throws -> String {
        let scriptDetails = try await rpcInterface.decodeScript(script: MOCK_OUTPUT_SCRIPT)
        let fakeAddress = ((scriptDetails["segwit"] as! [String: Any])["address"] as! String)
        return fakeAddress
    }
        
    func start() -> Promise<Void> {
        Promise { resolve, reject in
            all(
                self.alice.startSDK(), self.bob.startSDK()
            ).then { _, _ in
                resolve(())
            }
            .catch { error in
                print("SWAP SDK TEST: Sdk starting error")
                reject(error)
            }
        }
    }
    
    func aliceSubmitLimitOrder() -> Promise<Order> {
        Promise { [unowned self] fulfill, reject in
            alice.submitLimitOrder(side: "ask").then { order in
                fulfill(order)
            }
            .catch { error in
                print("SWAP SDK TEST: Alice: submitting order error: \(error)")
                reject(error)
            }
        }
    }
    
    func bobSubmitLimitOrder() -> Promise<Order> {
        Promise { [unowned self] fulfill, reject in
            bob.submitLimitOrder(side: "bid").then { order in
                fulfill(order)
            }
            .catch { error in
                print("SWAP SDK TEST: Bob: submitting order error: \(error)")
                reject(error)
            }
        }
    }
    
    deinit {
        print("Sample deinited")
    }
}
