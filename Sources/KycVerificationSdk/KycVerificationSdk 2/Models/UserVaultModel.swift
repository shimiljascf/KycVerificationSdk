//
//  UserVaultModel.swift
//  KycVerificationSdk
//
//  Created by Renu Bisht on 03/10/24.
//

import Foundation


@objc public class CFSecureShareResponse: NSObject {
    public var  verificationId: String?
    public var  authCode: String?
    public var  status: String?
}

@objc public class CFSecureShareErrorResponse: NSObject {
    public var  verificationId: String?
    public var  status: String?
}

@objc public class CFUserDropResponse: NSObject {
    public var  verificationId: String?
    public var  status: String?
}

struct SecureShareWebResponse: Codable {
    public var  verification_id: String?
    public var  auth_code: String?
    public var  status: String?
}

