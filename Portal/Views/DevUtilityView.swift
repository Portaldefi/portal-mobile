//
//  DevUtilityView.swift
//  Portal
//
//  Created by farid on 19.09.2023.
//

import SwiftUI
import PortalUI
import PopupView

import Combine
import Lightning
import Factory

@Observable class DevUtilityService {
    enum ConfirmationAlertType {
        case sent1BtcToOwnAddress(String), mined1Block(String), generatedAddress(String), sent1EthToOwnAccount(String)
    }
    enum ErrorAlertType {
        case sending1BtcToOwnAddress(String), miningBlock(String), sending1EthToOwnAccount(String)
    }
    
    var showConfirmationAlert = false
    var showErrorAlert = false
    var confirmationAlertType: ConfirmationAlertType?
    var errorAlertType: ErrorAlertType?
    
    private func callBTCRpcMethod(method: String, params: Any) async throws -> [String: Any] {
        let body: [String: Any] = [
            "method": method,
            "params": params
        ]
        let jsonBody = try JSONSerialization.data(withJSONObject: body)
        guard let rpcUrl = URL(string: "http://lnd:lnd@localhost:18443") else {
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
    
//    private func callLNApiMethod(endpoint: String, method: String = "POST", params: [String: Any]) async throws -> [String: Any] {
//        let url = URL(string: "http://localhost:10001/\(endpoint)")!
//        var request = URLRequest(url: url)
//        request.httpMethod = method
//        
//        // If the API uses JSON request bodies, serialize the parameters to JSON
//        let jsonData = try JSONSerialization.data(withJSONObject: params)
//        request.httpBody = jsonData
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        // If your API requires authentication, set the appropriate authentication headers
//        // request.setValue("Bearer your-api-token", forHTTPHeaderField: "Authorization")
//        
//        let (data, response) = try await URLSession.shared.data(for: request)
//        
//        // Check the HTTP response status code
//        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
//            // Handle HTTP error
//            throw LNApiError.httpError(httpResponse.statusCode)
//        }
//        
//        // Deserialize the JSON response
//        let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
//        guard let responseDict = jsonResponse as? [String: Any] else {
//            throw LNApiError.invalidResponse
//        }
//        
//        return responseDict
//    }
    
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
    
//    func createInvoice(amount: Int) async {
//        do {
//            let response = try await callLNApiMethod(endpoint: "addinvoice", params: ["value": amount])
//            let paymentRequest = response["payment_request"] as! String
//            print("Created invoice with payment request: \(paymentRequest)")
//        } catch {
//            print("Failed to create invoice: \(error)")
//        }
//    }
    
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
        
    }
    
    func fetchBobPubKey() async {
        
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

struct DevUtilityView: View {
    @EnvironmentObject private var navigation: NavigationStack
    @State private var utilityService: DevUtilityService
    
    init() {
        _utilityService = State(initialValue: DevUtilityService())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                PButton(config: .onlyIcon(Asset.caretLeftIcon), style: .free, size: .medium, enabled: true) {
                    navigation.pop()
                }
                .frame(width: 20)
                
                Spacer()
            }
            .padding(.horizontal, 25)
            .padding(.bottom, 22)
        
            List {
                Section(header: Text("Bitcoin")) {
                    Text("Send 1 btc to own account")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task { await utilityService.btcSend1ToOwnAccount() }
                        }
                    
                    Text("Generate new address")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task {
                                UIPasteboard.general.string = try await utilityService.getNewAddress()
                            }
                        }
                    
                    Text("Mine 1 block")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task { await utilityService.btcMineBlocks() }
                        }
                    
                    Text("Mine 6 block")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task { await utilityService.btcMineBlocks(count: 6) }
                        }
                }
                .headerProminence(.increased)
                
                Section(header: Text("Lightning: Alice")) {
                    Text("Add Invoice")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            //Task { await utilityService.createInvoice(amount: 1000) }
                        }
                    Text("Pay Invoice")
                }
                .headerProminence(.increased)
                
                Section(header: Text("Lightning: Bob")) {
                    Text("Add Invoice")
                    Text("Pay Invoice")
                }
                .headerProminence(.increased)
                
                Section(header: Text("Ethereum")) {
                    Text("Send 1 eth to own address")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task { await utilityService.send1EthToOwnAddress() }
                        }
                }
                .headerProminence(.increased)
            }
            .padding(.horizontal, 6)
            
            Spacer()
        }
        //Confirmation alert
        .popup(isPresented: $utilityService.showConfirmationAlert) {
            if let confirmationAlertType = utilityService.confirmationAlertType {
                HStack {
                    ZStack {
                        Circle()
                            .foregroundColor(Color(red: 0.191, green: 0.858, blue: 0.418))
                        Asset.checkIcon
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.black)
                    }
                    .frame(width: 32, height: 32)
                    .padding(.horizontal, 12)
                    
                    switch confirmationAlertType {
                    case .sent1BtcToOwnAddress(let txID):
                        Text("Tx id: \(txID)")
                            .multilineTextAlignment(.leading)
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                    case .mined1Block(let txID):
                        Text("Tx id: \(txID)")
                            .multilineTextAlignment(.leading)
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                    case .generatedAddress(let address):
                        Text("\(address)/n copied to clipboard")
                            .multilineTextAlignment(.leading)
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                    case .sent1EthToOwnAccount(let txID):
                        Text("Tx id: \(txID)")
                            .multilineTextAlignment(.leading)
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                    }
                    Spacer()
                }
                .frame(width: 300)
                .background(Color(red: 0.165, green: 0.165, blue: 0.165))
                .cornerRadius(16)
            } else {
                EmptyView()
            }
        } customize: {
            $0.autohideIn(2).type(.floater()).position(.top).animation(.spring()).closeOnTapOutside(true)
        }
        //Error alert
        .popup(isPresented: $utilityService.showErrorAlert) {
            if let errorAlertType = utilityService.errorAlertType {
                HStack {
                    ZStack {
                        Circle()
                            .foregroundColor(Color.red)
                        Asset.checkIcon
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.black)
                    }
                    .frame(width: 32, height: 32)
                    .padding(.horizontal, 12)
                    
                    switch errorAlertType {
                    case .sending1BtcToOwnAddress(let error):
                        Text(error)
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(.white)
                    case .miningBlock(let error):
                        Text(error)
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(.white)
                    case .sending1EthToOwnAccount(let error):
                        Text(error)
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
                .frame(width: 300)
                .background(Color(red: 0.165, green: 0.165, blue: 0.165))
                .cornerRadius(16)
            } else {
                EmptyView()
            }
        } customize: {
            $0.autohideIn(5).type(.floater()).position(.top).animation(.spring()).closeOnTapOutside(true)
        }
    }
}

struct DevUtilityView_Previews: PreviewProvider {
    static var previews: some View {
        DevUtilityView()
    }
}
