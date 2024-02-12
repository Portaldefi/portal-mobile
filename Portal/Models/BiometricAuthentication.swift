//
//  BiometricAuthentication.swift
//  Portal
//
//  Created by farid on 9/2/22.
//

import Foundation
import LocalAuthentication

class BiometricAuthentication {
    private var policyError: NSError?

    private func canEvaluatePolicy() -> Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &policyError)
    }

    func authenticateUser(completion: @escaping (Bool, LAError?) -> Void) {
        guard canEvaluatePolicy() else {
            completion(false, LAError(.biometryNotEnrolled))
            return
        }
        
        let reason = "Biometrics authentication is needed to sign transactions"

        LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(true, nil)
                } else if let error = error as? LAError {
                    completion(false, error)
                } else {
                    completion(false, LAError(.authenticationFailed))
                }
            }
        }
    }

    func isBiometricEnrolled() -> Bool {
        canEvaluatePolicy()
    }
}
