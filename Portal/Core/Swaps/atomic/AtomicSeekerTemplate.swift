//
//  AtomicSeekerTemplate.swift
//  Portal
//
//  Created by farid on 5/5/23.
//

import Foundation
import HsCryptoKit
import Factory
import PortalSwapSDK

struct InvoiceCodable: Codable {
    let created_at: String
    let id: String
    let mtokens: String
    let request: String
    let tokens: Int64
    
    private enum CodingKeys: String, CodingKey {
        case created_at, id, mtokens, request, tokens
    }
}

class AtomicSeekerTemplate: IAtomicSwap {
    private let host = "localhost"
    private let port = 64943
    
    private let ethereumKit: IAdapter & ISendEthereumAdapter
    private let lightningKit: ILightningInvoiceHandler & IBitcoinCore
    
    private var payDescriptor: String?
    
    var swap: SwapModel?
    var secretHash: String = "ignored"
    var id: String = "bob"
    
    init(ethereumKit: IAdapter & ISendEthereumAdapter, lightningKit: ILightningInvoiceHandler & IBitcoinCore) {
        self.ethereumKit = ethereumKit
        self.lightningKit = lightningKit
    }
    
    func open() async throws {
        guard let swap = swap else { return }

        print("[SWAP] Open in seeker atomic")
        
        guard let secretHash = swap.secretHash else { return }
        
        let quantity: Int64 = 1000
 
        if let invoice = await lightningKit.createInvoice(paymentHash: secretHash, satAmount: UInt64(quantity)) {
            print("[SWAP] secret holder lightning invoice: \(invoice)")
            
            let timestamp = invoice.timestamp()
            let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            let dateString = dateFormatter.string(from: date)
            
            let miliSats = "\(invoice.amountMilliSatoshis() ?? 0)"
            
            let invoiceCodable = InvoiceCodable(
                created_at: dateString,
                id: secretHash,
                mtokens: miliSats,
                request: invoice.toStr(),
                tokens: quantity
            )
            
//            let updatedSwap = updateState(swap: swap, state: ["\(swap.secretHolder.network.name)" : ["invoice" : invoiceCodable]])
//            print("[SWAP] updated swap: \(updatedSwap)")
            
            do {
                try await signalSwapOpen(swap: swap)
                print("[SWAP] updated to server")
            } catch {
                print(error)
            }
        }
    }
    
    func updateState(swap: SwapModel, state: [String : [String: InvoiceCodable]]) -> SwapModel? {
        let secretHolder = swap.secretSeeker
        
//        let secretHolderUpdated = Party(
//            id: secretHolder.id,
//            swap: secretHolder.swap,
//            asset: secretHolder.asset,
//            network: secretHolder.network,
//            quantity: secretHolder.quantity,
//            state: state,
//            isSecretSeeker: secretHolder.isSecretSeeker,
//            isSecretHolder: secretHolder.isSecretHolder
//        )
//        
//        return Swap(
//            id: swap.id,
//            secretHash: swap.secretHash,
//            secretHolder: secretHolderUpdated,
//            secretSeeker: swap.secretSeeker,
//            status: swap.status
//        )
        return nil
    }
    
    private func signalSwapOpen(swap: SwapModel) async throws {
        let urlString = "http://\(host):\(port)/api/v1/swap"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            throw SwapError.invalidURL
        }
            
//        let encoder = JSONEncoder()
//        let swapData = try encoder.encode(swap)
//        let swapDict = try JSONSerialization.jsonObject(with: swapData)
//        let userId = id
//        
//        let credentialsDict: [String: [String : String]] = [
//            "lightning" : [
//                "socket": "localhost:10001",
//                "cert": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNKekNDQWN5Z0F3SUJBZ0lRTDBsRGVKSnRGQm80ZE5KMW9oVCtFekFLQmdncWhrak9QUVFEQWpBeE1SOHcKSFFZRFZRUUtFeFpzYm1RZ1lYVjBiMmRsYm1WeVlYUmxaQ0JqWlhKME1RNHdEQVlEVlFRREV3VmhiR2xqWlRBZQpGdzB5TXpBMU1Ea3hORFExTXpGYUZ3MHlOREEzTURNeE5EUTFNekZhTURFeEh6QWRCZ05WQkFvVEZteHVaQ0JoCmRYUnZaMlZ1WlhKaGRHVmtJR05sY25ReERqQU1CZ05WQkFNVEJXRnNhV05sTUZrd0V3WUhLb1pJemowQ0FRWUkKS29aSXpqMERBUWNEUWdBRWhLY0haRW02dmozQnFOWlBHUHkyc0ovbHBXNEU4a1J5N1ZMS2hzVEFFY3VTUk9sRQpOUytOT1h2TmthS3BXbExzZzRLK0JtYjgzUHhTRm9URUNwRUJqcU9CeFRDQndqQU9CZ05WSFE4QkFmOEVCQU1DCkFxUXdFd1lEVlIwbEJBd3dDZ1lJS3dZQkJRVUhBd0V3RHdZRFZSMFRBUUgvQkFVd0F3RUIvekFkQmdOVkhRNEUKRmdRVURRZzJ6NGQyMW8vSnNlTEI3NVRIb2tDYjEyQXdhd1lEVlIwUkJHUXdZb0lGWVd4cFkyV0NDV3h2WTJGcwphRzl6ZElJRllXeHBZMldDRG5CdmJHRnlMVzR4TFdGc2FXTmxnZ1IxYm1sNGdncDFibWw0Y0dGamEyVjBnZ2RpCmRXWmpiMjV1aHdSL0FBQUJoeEFBQUFBQUFBQUFBQUFBQUFBQUFBQUJod1NzRWdBRE1Bb0dDQ3FHU000OUJBTUMKQTBrQU1FWUNJUUM1RDBwbW9lL3RlUGs4WDU4Ykl3WVVLNDRUbUNiSXkwd1MvYVJWa1VpdlpBSWhBTVU2bXBkdApxOGJtQWEwVUxDcld5TzRBbzNIMk1tYlUvSG81L2IzbGhabzAKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
//                "admin": "AgEDbG5kAvgBAwoQY+8iA8deGIvfBT1FSGpeHRIBMBoWCgdhZGRyZXNzEgRyZWFkEgV3cml0ZRoTCgRpbmZvEgRyZWFkEgV3cml0ZRoXCghpbnZvaWNlcxIEcmVhZBIFd3JpdGUaIQoIbWFjYXJvb24SCGdlbmVyYXRlEgRyZWFkEgV3cml0ZRoWCgdtZXNzYWdlEgRyZWFkEgV3cml0ZRoXCghvZmZjaGFpbhIEcmVhZBIFd3JpdGUaFgoHb25jaGFpbhIEcmVhZBIFd3JpdGUaFAoFcGVlcnMSBHJlYWQSBXdyaXRlGhgKBnNpZ25lchIIZ2VuZXJhdGUSBHJlYWQAAAYg4RigBZTfj34CoCvCBdHHZBA8tTwkCBN3B9t6iIaXuq0=",
//                "invoice": "AgEDbG5kAlgDChBh7yIDx14Yi98FPUVIal4dEgEwGhYKB2FkZHJlc3MSBHJlYWQSBXdyaXRlGhcKCGludm9pY2VzEgRyZWFkEgV3cml0ZRoPCgdvbmNoYWluEgRyZWFkAAAGIPpOnhuHT2qF1T4WAaxW06oxqpY7zy6t9oPP6ZxS96Ao"
//            ]
//        ]
//        
//        let credentialsEncoded = try encoder.encode(credentialsDict)
//        let credsJsonObject = try JSONSerialization.jsonObject(with: credentialsEncoded, options : .allowFragments)
//        
////        let partyData = try encoder.encode(swap.secretHolder)
////        let partyDataObject = try JSONSerialization.jsonObject(with: partyData)
//
//        let requestBody: [String: Any] = [
//            "swap": swapDict as Any,
////            "party": partyDataObject as Any,
//            "opts" : credsJsonObject as Any
//        ]
//                
//        let request = try buildRequest(url: url, method: "PUT", userId: userId, body: requestBody)
//        
//        let (data, _) = try await URLSession.shared.data(for: request)
//        if let responseString = String(data: data, encoding: .utf8) {
//            print("Response: \(responseString)")
//        } else {
//            print("No response data")
//            throw SwapError.emptyResponse
//        }
    }
    
    private func buildRequest(url: URL, method: String, userId: String, body: [String: Any]) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method

        let creds = "\(userId):\(userId)"

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let base64Creds = Data(creds.utf8).base64EncodedString()
        let contentType = "application/json"
        let contentLength = request.httpBody?.count ?? 0

        request.addValue(contentType, forHTTPHeaderField: "Accept")
        request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        request.addValue(contentType, forHTTPHeaderField: "Accept-Encoding")
        request.addValue("Basic \(base64Creds)", forHTTPHeaderField: "Authorization")
        request.addValue("identity", forHTTPHeaderField: "Content-Encoding")
        request.addValue("\(contentLength)", forHTTPHeaderField: "Content-Length")
        
        return request
    }
    
    func commit() async throws {
//        guard let swap = swap else { return }
        // Bob deposit funds to smart contract
    }
    
    func cancel() async throws {
        
    }

}
