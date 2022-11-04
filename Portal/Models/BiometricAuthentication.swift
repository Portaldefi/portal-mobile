//
//  BiometricAuthentication.swift
//  Portal
//
//  Created by farid on 9/2/22.
//

import Foundation
import LocalAuthentication
import Combine

class BiometricAuthentication: ObservableObject {
    private let context = LAContext()
    
    // .deviceOwnerAuthentication allows
    // biometric or passcode authentication
    private let authenticationPolicy: LAPolicy = .deviceOwnerAuthentication
    
    @Published private(set) var biometryType: LABiometryType
    @Published private(set) var permissionsGranted: Bool
    private var policyError: NSError?
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        biometryType = context.biometryType
        
        permissionsGranted = context.canEvaluatePolicy(
            authenticationPolicy,
            error: &policyError
        )
    }
    
    func authenticateUser(_ completion: @escaping (Bool, LAError?) -> ()) {
        context.evaluatePolicy(
            authenticationPolicy,
            localizedReason: "Authenticate to continue"
        ) { success, error in
            guard let error = error as? LAError else {
                return completion(success, nil)
            }
            completion(success, error)
        }
    }
}
