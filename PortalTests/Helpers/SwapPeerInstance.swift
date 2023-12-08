import Foundation
import Combine
import PortalSwapSDK
import Promises

class SwapParticipant: BaseClass {
    private let sdk: SDK
    private let ldkNode: LdkNode
    private var subscriptions = Set<AnyCancellable>()
    private let onSwapAccessQueue = DispatchQueue(label: "swap.sdk.onSwapAccessQueueTest")
    
    private let ldnPeerProps = LdkNode.LNDProps(
        pubKey: "0244007fef025b3cbdb0c342e480410818d60c4e22ce4d6a416296899c0689ed9f", address: "127.0.0.1", port: 9002
    )
    
    var isConnected: Bool {
        sdk.isConnected
    }
    
    let invocieToPayForBob = "lnbcrt250u1pjk7fsxpp5w9rx3qfk3u8aytwgvecpczy5gp0jm227x5cqjv7l7njagu5j09jsdqqcqzzsxqyz5vqsp5ghkk38jn9kpacs5z78yxsqe3a4uhzkqww92z8p2x9zl65rzt34jq9qyyssq7az3f0vp4r3cw2fzc8yu33f3j3jmcxg33h3ftfp0fx8cy8ufvtus74c2xqdl9z4r7yvmwy2xwxrcstsz9t2en726acplxzpj20pmg3qp26ql4l"
    
    private lazy var onSwap: ([Any]) -> Void = { [unowned self] args in
        if let data = args as? [Swap], let swap = data.first {
            self.onSwapAccessQueue.async {
                self.emit(event: "swap.\(swap.status)", args: [swap])
            }
        }
    }
    
    init(id: String, ethPrivKey: String, rpcInterface: RegtestBlockchainManager) async throws {
        print("SWAP SDK \(id) ldk node starting...")
        self.ldkNode = try await LdkNode(instanceId: id, ldnPeerProps: ldnPeerProps, rpcInterface: rpcInterface)
        print("SWAP SDK \(id) ldk node started")
        
        print("SWAP SDK \(id) ldk node opening a channel...")
        try await ldkNode.openChannel()
        print("SWAP SDK \(id) ldk channel opened")
        
        if id.contains("bob") {
            print("\(id) sends payment to increase inbound liquidity")
            let result = try await ldkNode.pay(swapId: id, request: invocieToPayForBob)
            print("\(id) payed invoice result: \(result.id)")
        }
                
        let network = SwapSdkConfig.Network(hostname: "localhost", port: 61280)
                
        guard let filePath = Bundle(for: EvmLightningSwapPlaynetTest.self).path(forResource: "contracts", ofType: "json") else {
            throw NSError(domain: "FileNotFound", code: 404, userInfo: nil)
        }

        let jsonString = try String(contentsOfFile: filePath, encoding: .utf8)
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "InvalidData", code: 500, userInfo: nil)
        }
        
        guard let contracts = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
            throw NSError(domain: "InvalidJSON", code: 500, userInfo: nil)
        }
        
        let ethereum = SwapSdkConfig.Blockchains.Ethereum(url: "ws://localhost:8545", chainId: "0x539", contracts: contracts, privKey: ethPrivKey)
        let lightning = SwapSdkConfig.Blockchains.Lightning(client: ldkNode)
        let blockchains = SwapSdkConfig.Blockchains(ethereum: ethereum, lightning: lightning)
        
        let sdkConfig = SwapSdkConfig(
            id: "\(id)",
            network: network,
            store: [:],
            blockchains: blockchains,
            dex: [:],
            swaps: [:]
        )
        
        sdk = SDK.init(config: sdkConfig)
        
        super.init(id: id)
        
        sdk.on("order.closed", { [unowned self] args in emit(event: "order.closed", args: args) }).store(in: &subscriptions)
        sdk.on("swap.received", onSwap).store(in: &subscriptions)
        sdk.on("swap.holder.invoice.paid", onSwap).store(in: &subscriptions)
        sdk.on("swap.seeker.invoice.paid", onSwap).store(in: &subscriptions)
        sdk.on("swap.completed", onSwap).store(in: &subscriptions)
    }
        
    func startSDK() -> Promise<Void> {
        Promise<Void> { [unowned self] fulfill, reject in
            sdk.start()
                .then { _sdk in
                    fulfill(())
                }
                .catch { error in
                    print("SWAP SDK TEST: SDK starting error: \(error)")
                    reject(error)
                }
        }
    }
    
    func submitLimitOrder(side: String) -> Promise<Order> {
        let order = OrderRequest(
            baseAsset: "BTC",
            baseNetwork: "lightning.btc",
            baseQuantity: 2500,
            quoteAsset: "ETH",
            quoteNetwork: "ethereum",
            quoteQuantity: 10000,
            side: side
        )
        
        return sdk.submitLimitOrder(order)
    }
}
