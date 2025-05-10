//
//  WebViewManager.swift
//  KycVerificationSdk
//
//  Created by Renu Bisht on 22/04/25.
//

import WebKit

class WebViewManager {
    private let webView: WKWebView

    init(webView: WKWebView) {
        self.webView = webView
    }

    func configure(delegate: WKNavigationDelegate, uiDelegate: WKUIDelegate, scriptHandler: WKScriptMessageHandler) {
        let config = webView.configuration
        config.userContentController.add(scriptHandler, name: "nativeProcess")

        let script = """
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.getElementsByTagName('head')[0].appendChild(meta);
        """
        config.userContentController.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))

        webView.navigationDelegate = delegate
        webView.uiDelegate = uiDelegate
        webView.backgroundColor = .white
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        } else {
            // Fallback on earlier versions
        }
    }

    func load(url: String) {
        guard let requestURL = URL(string: url) else { return }
        webView.load(URLRequest(url: requestURL))
    }
}
