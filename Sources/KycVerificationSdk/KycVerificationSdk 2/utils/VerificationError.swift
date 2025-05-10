//
//  KycVerificationError.swift
//  KycVerificationSdk
//
//  Created by Renu Bisht on 26/06/24.
//

import Foundation

@objc public enum VerificationError: Int,Error {
    case URL_MISSING
    case INVALID_URL
    case SESSION_ID_MISSING
}

extension VerificationError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .URL_MISSING:
            return "The \"formUrl\" is missing in the request."
        case .INVALID_URL:
               return "Please provide a proper URL."
           
        case .SESSION_ID_MISSING:
            return "SessionId is missing in the request"
        }
        
    }
    public var localizedDescription: String {
        get {
            return self.description
        }
    }
}
