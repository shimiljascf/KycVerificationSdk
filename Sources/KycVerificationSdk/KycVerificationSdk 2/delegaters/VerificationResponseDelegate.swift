//
//  VerificationResponseDelegate.swift
//  KycVerificationSdk
//
//  Created by Renu Bisht on 22/04/25.
//

import Foundation

@objc
public protocol VerificationResponseDelegate {
    func onVerificationCompletion(verificationResponse: CFVerificationResponse)
    func onErrorResponse(errorReponse: CFErrorResponse)
    func onVkycCloseResponse(verificationResponse: CFVKycCloseResponse)
}
