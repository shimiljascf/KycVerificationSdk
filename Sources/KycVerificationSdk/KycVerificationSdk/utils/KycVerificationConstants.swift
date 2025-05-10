//
//  KycVerificationConstants.swift
//  KycVerificationSdk
//
//  Created by Renu Bisht on 22/09/24.
//

import Foundation

struct KycVerificationConstants {
    static let validUrls = [
        "https://forms-test.cashfree.com",
        "https://forms.cashfree.com"
    ]
}

@objc public enum Environment: Int {
    case PROD
    case TEST
}

internal let SECURE_SHARE_BASEURL = "https://user-vault.cashfree.com/signup"
