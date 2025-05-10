//
//  KycVerificationViewController.swift
//  KycVerificationSdk
//
//  Created by Renu Bisht on 24/06/24.
//

import UIKit
import WebKit

class CFKycVerificationViewController: UIViewController {

    private var url: String
    private var accessToken: String?
    private var responseDelegate: VerificationResponseDelegate

    private var webViewManager: WebViewManager!
    private var jsBridgeHandler: JSBridgeHandler!

    @IBOutlet weak var kycWebView: WKWebView!

    init(url: String, accessToken: String?, delegate: VerificationResponseDelegate) {
        self.url = url
        self.accessToken = accessToken
        self.responseDelegate = delegate
        super.init(nibName: "CFKycVerificationViewController", bundle: Bundle(for: CFKycVerificationViewController.self))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        webViewManager = WebViewManager(webView: kycWebView)
        jsBridgeHandler = JSBridgeHandler(webView: kycWebView, accessToken: accessToken, delegate: responseDelegate, viewController: self)

        webViewManager.configure(delegate: self, uiDelegate: self, scriptHandler: jsBridgeHandler)
        webViewManager.load(url: url)
        hideBackButton()
        addSwipeGesture()

        NotificationCenter.default.addObserver(self, selector: #selector(handleAppDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    private func hideBackButton() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func addSwipeGesture() {
        let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleSwipeFromLeftEdge(_:)))
        gesture.edges = .left
        view.addGestureRecognizer(gesture)
    }

    @objc private func handleSwipeFromLeftEdge(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .recognized {
            showCancellationAlert()
        }
    }

    private func showCancellationAlert() {
        let alert = UIAlertController(title: "Warning", message: "Are you sure you want to cancel the verification?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.navigationController?.popViewController(animated: true)
            let errorResponse = CFErrorResponse()
            errorResponse.message = "User cancelled Verification"
            self.responseDelegate.onErrorResponse(errorReponse: errorResponse)
        })
        alert.addAction(UIAlertAction(title: "No", style: .default))
        present(alert, animated: true)
    }

    @objc private func handleAppDidBecomeActive() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.kycWebView.evaluateJavaScript("document.readyState") { result, error in
                if let state = result as? String, state != "complete" {
                    print("WebView not fully loaded. Reloading URL...")
                    self.webViewManager.load(url: self.url)
                } else {
                    print("WebView still active, no reload needed.")
                }
            }
        }
    }
}

extension CFKycVerificationViewController: WKNavigationDelegate, WKUIDelegate {

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        print("WKWebView content process terminated, reloading...")
        webViewManager.load(url: url)
    }
}
