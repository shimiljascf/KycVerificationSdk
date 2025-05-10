//
//  CFKycVerificationService.swift
//  KycVerificationSdk
//
//  Created by Renu Bisht on 25/06/24.
//

import Foundation
import UIKit

@objc
final public class CFVerificationService : NSObject{
    
    static let shared = CFVerificationService()
    
    private override init(){}
    
    static public func getInstance() -> CFVerificationService {
        return CFVerificationService.shared
    }
    
    @objc
    public func doVerification(_ url: String,_ viewController: UIViewController,_ callback: VerificationResponseDelegate,_ accessToken: String? = nil) throws{
        
       
        // 1. Validate base URL
            guard !url.isEmpty else {
                throw VerificationError.URL_MISSING
            }

            // 2. Compute `mode` parameter
            let modeParam = (accessToken?.isEmpty ?? true) ? "OTP" : "OTP_LESS"

            // 3. Build updated URL with mode as query param
            var updatedUrlString = url
            if url.contains("?") {
                updatedUrlString += "&mode=\(modeParam)"
            } else {
                updatedUrlString += "?mode=\(modeParam)"
            }

            // 4. Validate final URL
            guard let _ = URL(string: updatedUrlString) else {
                throw VerificationError.INVALID_URL
            }

    
        
        guard let navigationController = viewController.navigationController else {
                    throw NSError(domain: "NavigationControllerNotFound", code: 1, userInfo: nil)
                }
       // init(url: String, accessToken: String?, delegate: VerificationResponseDelegate) {
        
        let vc = CFKycVerificationViewController(url: updatedUrlString, accessToken: accessToken,delegate: callback)
      
        
        navigationController.pushViewController(vc, animated: true)
        
        
    
        
    }
    
    @objc
       public func openSecureShare(_ sessionId: String,_ environment: Environment, _ viewController: UIViewController, _ callback: CFSecureShareResponseDelegate) throws {
           
           guard !sessionId.isEmpty else {
                   throw VerificationError.SESSION_ID_MISSING
               }
           
           let userVaultVC = UserVaultViewController(sessionId: sessionId,environment: environment, callback: callback)
           
          
           userVaultVC.modalPresentationStyle = .custom
           userVaultVC.transitioningDelegate = userVaultVC
           
           
           viewController.present(userVaultVC, animated: true, completion: nil)
       }
    
    
}
