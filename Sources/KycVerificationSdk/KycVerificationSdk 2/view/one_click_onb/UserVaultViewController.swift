//
//  UserVaultViewController.swift
//  KycVerificationSdk
//
//  Created by Renu Bisht on 24/09/24.
//

import UIKit
import WebKit

@objc
public protocol CFSecureShareResponseDelegate {
    
    func onVerification(_ verificationResponse: CFSecureShareResponse)
    func onVerificationError(_ errorResponse: CFSecureShareErrorResponse)
    func onUserDrop(_ userDropResponse: CFUserDropResponse)
}

class UserVaultViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate, UIViewControllerTransitioningDelegate {
    
    private var webView: WKWebView!
    private var sessionId: String
    private var delegate: CFSecureShareResponseDelegate!
    private var environment: Environment
    
    
    private var loader: UIActivityIndicatorView!
    
    public init(sessionId: String, environment: Environment,callback: CFSecureShareResponseDelegate?) {
        self.sessionId = sessionId
        self.environment = environment
        self.delegate = callback
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        setupUI()
        setupWebViewConfigurations()
        loadWebView()
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    
    private func setupUI() {
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        let paddingTop: CGFloat = 20
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: paddingTop),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        
        webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: containerView.topAnchor),
            webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        
        loader = UIActivityIndicatorView(style: .large)
        loader.translatesAutoresizingMaskIntoConstraints = false
        loader.hidesWhenStopped = true
        view.addSubview(loader)
        
        NSLayoutConstraint.activate([
            loader.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupWebViewConfigurations() {
        let webViewConfig = webView.configuration
        let userScript = WKUserScript(source: """
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.getElementsByTagName('head')[0].appendChild(meta);
        """, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        webViewConfig.userContentController.addUserScript(userScript)
        webViewConfig.userContentController.add(self, name: "nativeProcess")
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
    }
    
    
    private func loadWebView() {
       
        var urlString = "\(SECURE_SHARE_BASEURL)?session_id=\(sessionId)"
        if environment != Environment.PROD {
            urlString += "&env=\(environment)"
        }
        guard let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url)
        loader.startAnimating()
        webView.load(request)
    }
    
    
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let messageBody = message.body as? [String: Any],
              let action = messageBody["action"] as? String,
              let verificationData = messageBody["data"] as? String else { return }
        let json = verificationData.data(using: .utf8)
        guard let nonNilData = json else {
            print("Data is nil")
            return
        }
        if let webResponse: SecureShareWebResponse = decodeJSON(from: nonNilData, as: SecureShareWebResponse.self) {
            switch action {
            case "verificationResponse":
                onVerificationResponse(webResponse)
            case "onClose":
                onClose(webResponse)
            case "errorResponse":
                errorResponse(webResponse)
            default:
                break
            }
        }
        
    }
    
    func onVerificationResponse(_ data: SecureShareWebResponse) {
        let vaultAuthResponse = CFSecureShareResponse()
        vaultAuthResponse.authCode = data.auth_code
        vaultAuthResponse.verificationId = data.verification_id
        vaultAuthResponse.status = data.status
        delegate.onVerification(vaultAuthResponse)
        self.dismiss(animated: true, completion: nil)
    }
    
    func errorResponse(_ data: SecureShareWebResponse) {
        let vaultErrorResponse = CFSecureShareErrorResponse()
        vaultErrorResponse.status = data.status
        vaultErrorResponse.verificationId = data.verification_id
        delegate.onVerificationError(vaultErrorResponse)
        self.dismiss(animated: true, completion: nil)
    }
    
    func onClose(_ data: SecureShareWebResponse) {
        let userDropResponse = CFUserDropResponse()
        userDropResponse.verificationId = data.verification_id
        userDropResponse.status = data.status
        delegate.onUserDrop(userDropResponse)
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loader.stopAnimating()
    }
    
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return UserVaultPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    func notifyBackgroundTap() {
        let userDropResponse = CFUserDropResponse()
        userDropResponse.verificationId = nil
        userDropResponse.status = "CLOSED"
        delegate?.onUserDrop(userDropResponse)
    }
}
