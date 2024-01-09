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
        pubKey: "03debebcf97019c836cab78633ecc228d4545d125ea5717bce86159ab5bf043488", address: "127.0.0.1", port: 9001
    )
    
    var isConnected: Bool {
        sdk.isConnected
    }
    
    let invocieToPayForBob = "lnbcrt1m1pjc27dcpp5tk66sa2g0388gy6zshlqjc46sh98ej3s2smnsnwt4e8agf740ctsdqqcqzzsxqyz5vqsp50u42zark4sqqrupwee83ka3rzelfrmrdmlvc90yqr4g5p4srcsks9qyyssq8gzvgyt5par7wn3chd63hrrst5jlq5gxcyn550qvjlyx0hc869u84sp2h2kct479wle5f92y9e80ypuhk0s9e69j5ymefmdma0tn0dcp926zur"
    
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
                
        let network = SwapSdkConfig.Network(networkProtocol: .unencrypted, hostname: "localhost", port: 61280)
                
        guard let filePath = Bundle(for: EvmLightningSwapPlaynetTest.self).path(forResource: "playnetContract", ofType: "json") else {
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
