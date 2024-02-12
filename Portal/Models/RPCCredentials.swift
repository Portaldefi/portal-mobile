//
//  RPCCredentials.swift
//  Portal
//
//  Created by farid on 09.10.2023.
//

import Foundation

public struct RpcCredentials: Codable {
    public let host: String
    public let port: Int
    public let certificate: String
    public let macaroon: String

    public init(host: String, port: Int, certificate: String, macaroon: String) {
        self.host = host
        self.port = port
        self.certificate = certificate
        self.macaroon = macaroon
    }
}

extension RpcCredentials: CustomStringConvertible {
    public var description: String {
        "[host: \(host); port: \(port); certificate: \(certificate.count) char(s); macaroon: \(macaroon.count) char(s)]"
    }
}
