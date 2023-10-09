//
//  DevUtilityService.swift
//  Portal
//
//  Created by farid on 09.10.2023.
//

import Foundation
import GRPC
import NIO
import NIOSSL
import NIOHPACK
import Factory
import UIKit

@Observable class DevUtilityService {
    enum ConfirmationAlertType {
        case sent1BtcToOwnAddress(String),
             mined1Block(String), 
             generatedAddress(String),
             sent1EthToOwnAccount(String), 
             aliceCreatesInvoice(String),
             bobCreatesInvoice(String)
    }
    enum ErrorAlertType {
        case sending1BtcToOwnAddress(String),
             miningBlock(String),
             sending1EthToOwnAccount(String),
             aliceCreatingInvoice(String),
             bobCreatingInvoice(String)
    }
    
    var showConfirmationAlert = false
    var showErrorAlert = false
    var confirmationAlertType: ConfirmationAlertType?
    var errorAlertType: ErrorAlertType?
    
    @ObservationIgnored var lndAliceClient: Lnrpc_LightningNIOClient?
    @ObservationIgnored var lndBobClient: Lnrpc_LightningNIOClient?
    
    init() {
        do {
            try setupAliceLnd()
        } catch {
            print("Alice lnd error: \(error)")
        }
    }
        
    private func callBTCRpcMethod(method: String, params: Any) async throws -> [String: Any] {
        let body: [String: Any] = [
            "method": method,
            "params": params
        ]
        
        let jsonBody = try JSONSerialization.data(withJSONObject: body)
        guard let rpcUrl = URL(string: "http://lnd:lnd@localhost:18443/wallet/default") else {
            throw ChainManagerError.invalidUrlString
        }
        var request = URLRequest(url: rpcUrl)
        request.httpMethod = "POST"
        request.httpBody = jsonBody
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONSerialization.jsonObject(with: data, options: .topLevelDictionaryAssumed)
        // print("JSON-RPC response: \(response)")
        let responseDictionary = response as! [String: Any]
        if let responseError = responseDictionary["error"] as? [String: Any] {
            let errorDetails = RPCErrorDetails(message: responseError["message"] as! String, code: responseError["code"] as! Int64)
            print("error details: \(errorDetails)")
            throw RpcError.errorResponse(errorDetails)
        }
        return responseDictionary
    }
    
    private func callEthRpcMethod(method: String, params: Any) async throws -> [String: Any] {
        let url = URL(string: "http://localhost:8545")!
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
            "id": 1
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        // Using URLSession async version
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        return json
    }
    
    func btcSend1ToOwnAccount() async {
        guard let btcDepositAdapter = Container.bitcoinDepositAdapter() else { return }
        do {
            let response = try await callBTCRpcMethod(method: "sendtoaddress", params: [btcDepositAdapter.receiveAddress, 1])
            let txID = response["result"] as! String
            print("Sent 1 Btc to \(btcDepositAdapter.receiveAddress), txID: \(txID)")
            
            DispatchQueue.main.async {
                self.confirmationAlertType = .sent1BtcToOwnAddress(txID)
                self.showConfirmationAlert = true
            }
        } catch {
            if let rpcError = error as? RpcError {
                DispatchQueue.main.async {
                    switch rpcError {
                    case .tcpError:
                        self.errorAlertType = .sending1BtcToOwnAddress("TCP Error")
                    case .invalidJson:
                        self.errorAlertType = .sending1BtcToOwnAddress("Invalid JSON")
                    case .errorResponse(let rPCErrorDetails):
                        self.errorAlertType = .sending1BtcToOwnAddress("\(rPCErrorDetails.message), code: \(rPCErrorDetails.code)")
                    }
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    func btcMineBlocks(count: Int = 1) async {
        do {
            let address = try await getNewAddress(showAlert: false)
            let response = try await self.callBTCRpcMethod(method: "generatetoaddress", params: [
                "nblocks": count,
                "address": address
            ] as [String : Any])
            
            let txID = (response["result"] as! [String]).first!
            
            print("Mined 1 block txID: \(txID)")
            
            DispatchQueue.main.async {
                self.confirmationAlertType = .mined1Block(txID)
                self.showConfirmationAlert = true
            }
        } catch {
            if let rpcError = error as? RpcError {
                DispatchQueue.main.async {
                    switch rpcError {
                    case .tcpError:
                        self.errorAlertType = .miningBlock("TCP Error")
                    case .invalidJson:
                        self.errorAlertType = .miningBlock("Invalid JSON")
                    case .errorResponse(let rPCErrorDetails):
                        self.errorAlertType = .miningBlock("\(rPCErrorDetails.message), code: \(rPCErrorDetails.code)")
                    }
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    func aliceCreateInvoice(amount: Int) async {
        guard let aliceLND = lndAliceClient else { return }
        
        var invoice = Lnrpc_Invoice()
        invoice.value = Int64(amount)
        
        do {
            let response = try await aliceLND.addInvoice(invoice).response.get()
            print("Alice invoice payment_request: \(response.paymentRequest)")
            
            UIPasteboard.general.string = response.paymentRequest
            
            DispatchQueue.main.async {
                self.confirmationAlertType = .aliceCreatesInvoice(response.paymentRequest)
                self.showConfirmationAlert = true
            }
        } catch {
            print("error: \(error)")
            self.errorAlertType = .aliceCreatingInvoice(error.localizedDescription)
            self.showErrorAlert = true
        }
    }
    
    func bobCreateInvoice(amount: Int) async {
        guard let bobLND = lndBobClient else { return }
        
        var invoice = Lnrpc_Invoice()
        invoice.value = Int64(amount)
        
        do {
            let response = try await bobLND.addInvoice(invoice).response.get()
            print("Bob invoice payment_request: \(response.paymentRequest)")
            
            UIPasteboard.general.string = response.paymentRequest
            
            DispatchQueue.main.async {
                self.confirmationAlertType = .bobCreatesInvoice(response.paymentRequest)
                self.showConfirmationAlert = true
            }
        } catch {
            print("error: \(error)")
            self.errorAlertType = .aliceCreatingInvoice(error.localizedDescription)
            self.showErrorAlert = true
        }
    }
    
    func getNewAddress(showAlert: Bool = true) async throws -> String {
        let response = try await self.callBTCRpcMethod(method: "getnewaddress", params: [])
        let result = response["result"] as! String
        
        if showAlert {
            DispatchQueue.main.async {
                self.confirmationAlertType = .generatedAddress(result)
                self.showConfirmationAlert = true
            }
        }
        
        return result
    }
    
    private func ethGetDefaultAccount() async throws -> String? {
        let response = try await callEthRpcMethod(method: "eth_accounts", params: [])
        if let result = response["result"] as? [String] {
            return result.first
        }
        
        return nil
    }

    private func ethSendTransaction(from account: String, to userAccount: String) async throws -> String? {
        let response = try await callEthRpcMethod(method: "eth_sendTransaction", params: [[
            "from": account,
            "to": userAccount,
            "value": "0x" + String(format: "%llx", UInt64(1 * 1e18))
        ]])
        
        return response["result"] as? String
    }
    
    func send1EthToOwnAddress() async {
        do {
            let ethKitManager = Container.ethereumKitManager()
            if let defaultAccount = try await ethGetDefaultAccount(), let toAddress = ethKitManager.ethereumKit?.receiveAddress.eip55 {
                if let txID = try await ethSendTransaction(from: defaultAccount, to: toAddress) {
                    DispatchQueue.main.async {
                        self.confirmationAlertType = .sent1EthToOwnAccount(txID)
                        self.showConfirmationAlert = true
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorAlertType = .sending1EthToOwnAccount(error.localizedDescription)
                self.showErrorAlert = true
            }
        }
    }
    
    func fetchAlicePubKey() async {
        guard let aliceLND = lndAliceClient else { return }
        do {
            let response = try await aliceLND.getInfo(Lnrpc_GetInfoRequest()).response.get()
            print("Alice pubKey: \(response.identityPubkey)")
        } catch {
            print("error: \(error)")
        }
    }
    
    func fetchBobPubKey() async {
        guard let bobLND = lndBobClient else { return }
        do {
            let response = try await bobLND.getInfo(Lnrpc_GetInfoRequest()).response.get()
            print("Alice pubKey: \(response.identityPubkey)")
        } catch {
            print("error: \(error)")
        }
    }
    
    private func setupAliceLnd() throws {
        if let url = Bundle.main.url(forResource: "alice", withExtension: "macaroon") {
            // Read the file into a Data object
            let data = try Data(contentsOf: url)
            
            // Convert the Data object to a hexadecimal string
            let hexString = data.map { String(format: "%02x", $0) }.joined()
            
            // Print or use the hexadecimal string
            print(hexString)
            
            let rpcCredentials = RpcCredentials(
                host: "localhost",
                port: 10001,
                certificate: """
-----BEGIN CERTIFICATE-----
MIIDgzCCAyigAwIBAgIQd/+RzONBosoLvpMuHCG7PjAKBggqhkjOPQQDAjA4MR8w
HQYDVQQKExZsbmQgYXV0b2dlbmVyYXRlZCBjZXJ0MRUwEwYDVQQDEwxjdWh0ZTMu
bG9jYWwwHhcNMjMwOTE5MDY1OTU1WhcNMjQxMTEzMDY1OTU1WjA4MR8wHQYDVQQK
ExZsbmQgYXV0b2dlbmVyYXRlZCBjZXJ0MRUwEwYDVQQDEwxjdWh0ZTMubG9jYWww
WTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAARka2TH1RcNJcdf4SWNSvfkIMMucYvq
xRUXs9rlC1BIGu5toHfzucMSBLm27+4ECBESlsxjhehxgwTUskJEBmn/o4ICEjCC
Ag4wDgYDVR0PAQH/BAQDAgKkMBMGA1UdJQQMMAoGCCsGAQUFBwMBMA8GA1UdEwEB
/wQFMAMBAf8wHQYDVR0OBBYEFOu3U2OnzOoDx/twZv7ZHKCRpiIyMIIBtQYDVR0R
BIIBrDCCAaiCDGN1aHRlMy5sb2NhbIIJbG9jYWxob3N0ggR1bml4ggp1bml4cGFj
a2V0ggdidWZjb25uhwR/AAABhxAAAAAAAAAAAAAAAAAAAAABhxD+gAAAAAAAAAAA
AAAAAAABhxD+gAAAAAAAANSQnf/+X8RYhxD+gAAAAAAAANSQnf/+X8RXhxD+gAAA
AAAAANSQnf/+X8RZhxD+gAAAAAAAAPTUiP/+fRiqhxD+gAAAAAAAABg6YieDBpWz
hwTAqAEDhxD9jBXHd2b1ABiMhr6/W+EPhxAkA2IAiHDWkRgiC4h5vIZbhxAkA2IA
iHDWkSG+CaQusdxThxAkA2IAiHDWkQAAAAAAAAAGhxD+gAAAAAAAAIgg8f/+B/jY
hxD+gAAAAAAAALgHQ6efkAIFhxD+gAAAAAAAALGWAib0PcYqhxD+gAAAAAAAAM6B
Cxy9LAaehxD+gAAAAAAAAB5lJIMmwQomhxD+gAAAAAAAAG6kgjCZs97UhxD+gAAA
AAAAAOqR8hrabur6hxD+gAAAAAAAAAwvv6bowfr7hxD+gAAAAAAAADiqS4TJGG7n
MAoGCCqGSM49BAMCA0kAMEYCIQDyYTY1GULcwF+LzUngnvyBar/kQLTBYopI5qjj
NUQgSQIhAMm2Y6IWL35Yrr/tkX8OFKaStyvKkqVRwUPkwToGpnuP
-----END CERTIFICATE-----
""",
                macaroon: hexString
            )

            let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            
            let certificateBytes: [UInt8] = Array(rpcCredentials.certificate.utf8)
            let certificate = try NIOSSLCertificate(bytes: certificateBytes, format: .pem)
            let tlsConfig = ClientConnection.Configuration.TLS(
                trustRoots: .certificates([certificate])
            )
            
            let callOptions = CallOptions(
                customMetadata: HPACKHeaders([("macaroon", rpcCredentials.macaroon)])
            )
            
            
            let config = ClientConnection.Configuration(
                target: .hostAndPort(rpcCredentials.host, rpcCredentials.port),
                eventLoopGroup: group,
                connectivityStateDelegate: self,
                tls: tlsConfig
            )
            
            let connection = ClientConnection(configuration: config)
            
            lndAliceClient = Lnrpc_LightningNIOClient(channel: connection, defaultCallOptions: callOptions)
        } else {
            throw LNApiError.noAliceMacaroon
        }
    }
    
    private func setupBobLnd() throws {
        if let url = Bundle.main.url(forResource: "bob", withExtension: "macaroon") {
            // Read the file into a Data object
            let data = try Data(contentsOf: url)
            
            // Convert the Data object to a hexadecimal string
            let hexString = data.map { String(format: "%02x", $0) }.joined()
            
            // Print or use the hexadecimal string
            print(hexString)
            
            let rpcCredentials = RpcCredentials(
                host: "localhost",
                port: 10002,
                certificate: """
-----BEGIN CERTIFICATE-----
MIIDgzCCAyigAwIBAgIQd/+RzONBosoLvpMuHCG7PjAKBggqhkjOPQQDAjA4MR8w
HQYDVQQKExZsbmQgYXV0b2dlbmVyYXRlZCBjZXJ0MRUwEwYDVQQDEwxjdWh0ZTMu
bG9jYWwwHhcNMjMwOTE5MDY1OTU1WhcNMjQxMTEzMDY1OTU1WjA4MR8wHQYDVQQK
ExZsbmQgYXV0b2dlbmVyYXRlZCBjZXJ0MRUwEwYDVQQDEwxjdWh0ZTMubG9jYWww
WTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAARka2TH1RcNJcdf4SWNSvfkIMMucYvq
xRUXs9rlC1BIGu5toHfzucMSBLm27+4ECBESlsxjhehxgwTUskJEBmn/o4ICEjCC
Ag4wDgYDVR0PAQH/BAQDAgKkMBMGA1UdJQQMMAoGCCsGAQUFBwMBMA8GA1UdEwEB
/wQFMAMBAf8wHQYDVR0OBBYEFOu3U2OnzOoDx/twZv7ZHKCRpiIyMIIBtQYDVR0R
BIIBrDCCAaiCDGN1aHRlMy5sb2NhbIIJbG9jYWxob3N0ggR1bml4ggp1bml4cGFj
a2V0ggdidWZjb25uhwR/AAABhxAAAAAAAAAAAAAAAAAAAAABhxD+gAAAAAAAAAAA
AAAAAAABhxD+gAAAAAAAANSQnf/+X8RYhxD+gAAAAAAAANSQnf/+X8RXhxD+gAAA
AAAAANSQnf/+X8RZhxD+gAAAAAAAAPTUiP/+fRiqhxD+gAAAAAAAABg6YieDBpWz
hwTAqAEDhxD9jBXHd2b1ABiMhr6/W+EPhxAkA2IAiHDWkRgiC4h5vIZbhxAkA2IA
iHDWkSG+CaQusdxThxAkA2IAiHDWkQAAAAAAAAAGhxD+gAAAAAAAAIgg8f/+B/jY
hxD+gAAAAAAAALgHQ6efkAIFhxD+gAAAAAAAALGWAib0PcYqhxD+gAAAAAAAAM6B
Cxy9LAaehxD+gAAAAAAAAB5lJIMmwQomhxD+gAAAAAAAAG6kgjCZs97UhxD+gAAA
AAAAAOqR8hrabur6hxD+gAAAAAAAAAwvv6bowfr7hxD+gAAAAAAAADiqS4TJGG7n
MAoGCCqGSM49BAMCA0kAMEYCIQDyYTY1GULcwF+LzUngnvyBar/kQLTBYopI5qjj
NUQgSQIhAMm2Y6IWL35Yrr/tkX8OFKaStyvKkqVRwUPkwToGpnuP
-----END CERTIFICATE-----
""",
                macaroon: hexString
            )

            let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            
            let certificateBytes: [UInt8] = Array(rpcCredentials.certificate.utf8)
            let certificate = try NIOSSLCertificate(bytes: certificateBytes, format: .pem)
            let tlsConfig = ClientConnection.Configuration.TLS(
                trustRoots: .certificates([certificate])
            )
            
            let callOptions = CallOptions(
                customMetadata: HPACKHeaders([("macaroon", rpcCredentials.macaroon)])
            )
            
            
            let config = ClientConnection.Configuration(
                target: .hostAndPort(rpcCredentials.host, rpcCredentials.port),
                eventLoopGroup: group,
                connectivityStateDelegate: self,
                tls: tlsConfig
            )
            
            let connection = ClientConnection(configuration: config)
            
            lndAliceClient = Lnrpc_LightningNIOClient(channel: connection, defaultCallOptions: callOptions)
        } else {
            throw LNApiError.noAliceMacaroon
        }
    }
}

extension DevUtilityService: ConnectivityStateDelegate {
    func connectivityStateDidChange(from oldState: GRPC.ConnectivityState, to newState: GRPC.ConnectivityState) {
        
    }
}

extension DevUtilityService {
    enum RpcError: Error {
        case tcpError
        case invalidJson
        case errorResponse(RPCErrorDetails)
    }

    struct RPCErrorDetails {
        let message: String
        let code: Int64
    }
    
    enum LNApiError: Error {
        case httpError(Int)
        case invalidResponse
        case noAliceMacaroon
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

