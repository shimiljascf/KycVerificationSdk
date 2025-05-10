//
//  JSBridgeHandler.swift
//  KycVerificationSdk
//
//  Created by Renu Bisht on 22/04/25.
//

import WebKit
import UIKit

class JSBridgeHandler: NSObject, WKScriptMessageHandler {
    weak var webView: WKWebView?
    weak var viewController: UIViewController?
    weak var responseDelegate: VerificationResponseDelegate?
    private var accessToken: String?
    private var permissionsManager = PermissionsManager()
    private var calendarManager = CalendarManager()
    private var shouldCheckPermissionsOnReturn = false // Flag for app return
    
    init(webView: WKWebView, accessToken: String?, delegate: VerificationResponseDelegate, viewController: UIViewController) {
        self.webView = webView
        self.accessToken = accessToken
        self.responseDelegate = delegate
        self.viewController = viewController
        
        super.init()
        
        webView.configuration.allowsPictureInPictureMediaPlayback = false
        
        
        setupAppStateListener()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    private func setupAppStateListener() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func handleAppDidBecomeActive() {
        if shouldCheckPermissionsOnReturn {
            requestPermissions()
            shouldCheckPermissionsOnReturn = false // Reset flag
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let messageBody = message.body as? [String: Any],
              let action = messageBody["action"] as? String else { return }
        
        let dataString = messageBody["data"] as? String
        
        
        print(action,"action")
        
        switch action {
        case "verificationResponse":
            handleVerificationResponse(dataString)
        case "webErrors":
            handleWebErrors(dataString)
        case "getToken":
            sendTokenToWeb()
        case "requestPermissions":
            requestPermissions()
        case "addToCalendar":
            addEventToCalendar(dataString)
        case "vKycOnClose":
            handleVKycOnClose(dataString)
        default:
            print("Unknown action: \(action)")
        }
    }
    
    private func handleVerificationResponse(_ data: String?) {
        guard let data = data, let jsonData = data.data(using: .utf8),
              let webResponse = try? JSONDecoder().decode(WebResponse.self, from: jsonData) else { return }
        
        let response = CFVerificationResponse()
        response.status = webResponse.status
        response.form_id = webResponse.form_id
        responseDelegate?.onVerificationCompletion(verificationResponse: response)
    }
    
    private func handleWebErrors(_ data: String?) {
        guard let data = data, let jsonData = data.data(using: .utf8),
              let webResponse = try? JSONDecoder().decode(WebResponse.self, from: jsonData) else { return }
        
        let error = CFErrorResponse()
        error.statusCode = webResponse.statusCode
        error.message = webResponse.message
        responseDelegate?.onErrorResponse(errorReponse: error)
    }
    
    private func sendTokenToWeb() {
        guard let token = accessToken else { return }
        let js = "setToken('\(token)')"
        webView?.evaluateJavaScript(js)
    }
    
    private func requestPermissions() {
        guard let controller = viewController else { return }
        
        permissionsManager.checkAndRequestPermissions(completion: { [weak self] camera, mic, location in
            guard let self = self else { return }
            
            let js = "setPermission(\(camera), \(mic), \(location))"
            self.webView?.evaluateJavaScript(js)
            
            if location {
                self.permissionsManager.fetchCurrentLocation { coordinate in
                    guard let coordinate = coordinate else { return }
                    let lat = coordinate.latitude
                    let lon = coordinate.longitude
                    
                    let js = "setLatLong('\(lat)', '\(lon)')"
                    self.webView?.evaluateJavaScript(js)
                }
            }
        }, from: controller, onSettingsRedirect: { [weak self] in
            // Set the flag when user goes to settings
            self?.shouldCheckPermissionsOnReturn = true
        })
    }
    
    private func addEventToCalendar(_ data: String?) {
        guard let data = data else {
            print("No calendar data provided")
            return
        }
        
        calendarManager.addEvent(from: data) { [weak self] success, message in
            let js = "updateCalendarStatus('\(message)', \(success))"
            self?.webView?.evaluateJavaScript(js)
        }
    }
    
    
    //    private func handleVKycOnClose(_ data: String?) {
    //        guard let data = data, let jsonData = data.data(using: .utf8),
    //              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
    //              let verificationId = json["verificationId"] as? String else { return }
    //
    //        let response = CFVKycCloseResponse()
    //        response.verificationId = verificationId
    //        responseDelegate?.onVkycCloseResponse(verificationResponse: response)
    //
    //        DispatchQueue.main.async { [weak self] in
    //
    //                 print("heloo---------->")
    //                // Navigate back to previous screen instead of dismissing
    //                if let navigationController = self?.viewController?.navigationController {
    //                    print("herer---------->")
    //                    navigationController.popViewController(animated: true)
    //                } else {
    //                    print("dismiss---------->")
    //                    // Fallback to dismiss if there's no navigation controller
    //                    self?.viewController?.dismiss(animated: true, completion: nil)
    //                }
    //            }
    //    }
    
    
    private func handleVKycOnClose(_ data: String?) {
        guard let data = data, let jsonData = data.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let verificationId = json["verificationId"] as? String else { return }
        
        let response = CFVKycCloseResponse()
        response.verificationId = verificationId
        responseDelegate?.onVkycCloseResponse(verificationResponse: response)
        
        // Store a local reference before async execution
        
        
    }
    

}
