//
//  Models.swift
//  KycVerificationSdk
//
//  Created by Renu Bisht on 03/07/24.
//

import Foundation


@objc public class CFVerificationResponse: NSObject {
    public var  status: String?
    public var  form_id: String?
}

@objc public class CFErrorResponse: NSObject {
    public var  message: String?
    public var  statusCode: Int?
}

struct WebResponse: Codable {
    let status: String?
    let form_id: String?
    let message: String?
    let statusCode: Int?
}



@objc public class CFVKycCloseResponse: NSObject {
    public var verificationId: String?

}
