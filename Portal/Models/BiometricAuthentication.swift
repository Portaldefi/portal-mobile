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
    private let authenticationPolicy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics
    
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
        print(permissionsGranted)
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
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?

        // check whether biometric authentication is possible
//        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
//            // it's possible, so go ahead and use it
//            let reason = "Biometrics authentication is needed to sign transactions"
//
//            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
//                // authentication has now completed
//                if success {
//                    // authenticated successfully
//                    self?.permissionsGranted = true
//                } else {
//                    // there was a problem
//                    self?.permissionsGranted = false
//                }
//            }
//        } else {
//            // no biometrics
//        }
        
        let reason = "Biometrics authentication is needed to sign transactions"

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
            // authentication has now completed
            if success {
                // authenticated successfully
                self?.permissionsGranted = true
            } else {
                // there was a problem
                self?.permissionsGranted = false
            }
        }
    }
}
