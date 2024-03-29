//
//  PeerStore.swift
//  Surge
//
//  Created by Jurvis on 9/11/22.
//

import Foundation

class PeerStore {
    static func clearPeersDocumentsDirectory() {
        do {
            let fileURL = try fileUrl()
            guard let _ = try? FileHandle(forReadingFrom: fileURL) else {
                return
            }
            
            
            try FileManager.default.removeItem(at: fileURL)
        } catch  {
            print(error)
        }
    }
    
    static func load(completion: @escaping (Result<[String:Peer], Error>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let fileURL = try fileUrl()
                guard let file = try? FileHandle(forReadingFrom: fileURL) else {
                    DispatchQueue.main.async {
                        completion(.success([:]))
                    }
                    return
                }
                
                let peers = try JSONDecoder().decode([String:Peer].self, from: file.availableData)
                DispatchQueue.main.async {
                    completion(.success(peers))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    static func save(peers: [Peer], completion: @escaping (Result<Int, Error>)->Void) {
        let dict = Dictionary(uniqueKeysWithValues: peers.map{ ($0.peerPubKey, $0) })
        
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try JSONEncoder().encode(dict)
                let outfile = try fileUrl()
                try data.write(to: outfile)
                DispatchQueue.main.async {
                    completion(.success(peers.count))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                    
                }
            }
        }
    }
    
    private static func fileUrl() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
            .appendingPathComponent("peersData")
    }
}
