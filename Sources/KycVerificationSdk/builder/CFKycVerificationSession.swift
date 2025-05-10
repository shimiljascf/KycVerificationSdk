//
//  CFKycVerificationSession.swift
//  KycVerificationSdk
//
//  Created by Renu Bisht on 26/06/24.
//


import Foundation
 
@objc
final public class CFKycVerificationSession: NSObject {
    
    private var formUrl: String!
    
    private init(builder: Builder) {
        self.formUrl = builder.getFormUrl()
    }
    
    public func getFormUrl() -> String {
        return self.formUrl
    }
    
    @objc
    final public class Builder: NSObject {
        
        private var formUrl: String!
        
        public override init() {
            super.init()
        }
        
        @objc
        public func setFormUrl(_ url: String) -> Builder {
            self.formUrl = url
            return self
        }
        
        @objc
        public func build() throws -> CFKycVerificationSession {
            guard self.formUrl != nil else {
                throw VerificationError.URL_MISSING
            }
            return CFKycVerificationSession(builder: self)
        }
        
        func getFormUrl() -> String? {
            return self.formUrl
        }
    }
}
