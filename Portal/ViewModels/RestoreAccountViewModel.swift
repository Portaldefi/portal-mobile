//
//  RestoreAccountViewModel.swift
// Portal
//
//  Created by farid on 8/9/22.
//

import Foundation
import Combine
import BitcoinDevKit
import Factory
import SwiftUI

class RestoreAccountViewModel: ObservableObject {
    @Published var accountName = String()
    @Published var input = String()
    @Published var restorable = false
    @Published var validInput = true
    @Published var clipboardIsEmpty = false
    @Published var isDetecting = false
    
    var accountKey: DescriptorSecretKey?
    
    @Injected(Container.accountManager) private var manager
    
    private var subscriptions = Set<AnyCancellable>()
        
    func validateInput() {
        withAnimation {
            isDetecting = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let words = self.input.components(separatedBy: " ").filter{ !$0.isEmpty && $0.count >= 3 }
            
            if words.count == 12 || words.count == 24 {
                do {
                    self.accountKey = try DescriptorSecretKey(network: .testnet, mnemonic: words.joined(separator:" "), password: nil)
                    self.restorable = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.isDetecting = false
                        self.validInput = true
                    }
                } catch {
                    print("restore error: \(error)")
                    
                    withAnimation {
                        self.isDetecting = false
                        self.validInput = false
                    }
                }

            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        self.validInput = false
                        self.isDetecting = false
                    }
                }
            }
        }
    }
    
    func pasteFromClipboard() {
        let pasteboard = UIPasteboard.general
        if let pastboardString = pasteboard.string {
            input = pastboardString
            validInput = true
        } else {
            clipboardIsEmpty.toggle()
        }
    }
    
    private func restoreAccount(words: [String]) {
        do {
            let restoredKey = try DescriptorSecretKey(network: .testnet, mnemonic: words.joined(separator:" "), password: nil)
            let account = Account(id: UUID().uuidString, index: 0, name: accountName, key: restoredKey)
            manager.save(account: account, mnemonic: words.joined(separator:" "), salt: nil)
        } catch {
            print("restore error: \(error)")
        }
    }
}
