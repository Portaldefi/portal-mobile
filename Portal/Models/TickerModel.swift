//
//  TickerModel.swift
//  Portal
//
//  Created by farid on 3/7/23.
//

import Foundation

struct TickerModel: Decodable {
    enum MessageType: String, Codable {
        case prev_close, quotes, sparkline
    }
    
    var ticker_id: String
    var prevClose: Double?
    var prev_Close: Double?
    var message_type: MessageType?
    var ts: String?
    var price: Double?
}
