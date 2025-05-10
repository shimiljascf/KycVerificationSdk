import UIKit
import WebKit

class CFKycVerificationViewController: UIViewController {

    // MARK: - Properties
    private var url: String
    private var accessToken: String?
    private var responseDelegate: VerificationResponseDelegate
    
    private var webViewManager: WebViewManager!
    private var jsBridgeHandler: JSBridgeHandler!
    
    // Replace IBOutlet with a regular property
    private var kycWebView: WKWebView!
    
    // Reference to webView's scrollView for controlling scrolling behavior
    private var webViewScrollView: UIScrollView?
    
    // Activity indicator for loading state
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .gray
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Initialization
    init(url: String, accessToken: String?, delegate: VerificationResponseDelegate) {
        self.url = url
        self.accessToken = accessToken
        self.responseDelegate = delegate
        
        // Initialize without a NIB
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    
    override func loadView() {
        // Create main view
        view = UIView()
        view.backgroundColor = .white
        
        // Create the WKWebView with configuration
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Disable Picture in Picture (PIP) mode
        if #available(iOS 14.0, *) {
            configuration.allowsPictureInPictureMediaPlayback = false
        }
        
        // Add a viewport meta tag script to ensure proper scaling
        let viewportScript = WKUserScript(
            source: "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'); document.getElementsByTagName('head')[0].appendChild(meta);",
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        configuration.userContentController.addUserScript(viewportScript)
        
        kycWebView = WKWebView(frame: .zero, configuration: configuration)
        kycWebView.translatesAutoresizingMaskIntoConstraints = false
        kycWebView.allowsBackForwardNavigationGestures = false
        
        // Fix scrolling issues by accessing scrollView
        webViewScrollView = kycWebView.scrollView
        webViewScrollView?.bounces = false
        webViewScrollView?.showsHorizontalScrollIndicator = false
        webViewScrollView?.showsVerticalScrollIndicator = true
        
        // Disable zooming for KYC verification flow
        webViewScrollView?.minimumZoomScale = 1.0
        webViewScrollView?.maximumZoomScale = 1.0
        
        // Disable zooming for KYC verification flow
        webViewScrollView?.minimumZoomScale = 1.0
        webViewScrollView?.maximumZoomScale = 1.0
        
        view.addSubview(kycWebView)
        
        // Add activity indicator
        view.addSubview(activityIndicator)
        
        // Set up constraints based on the Interface Builder layout
        NSLayoutConstraint.activate([
            // Center horizontally (matching Web View.centerX = centerX)
            kycWebView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Full width (matching Web View.leading = Safe Area.leading)
            kycWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            kycWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Top to top edge of screen (full screen, not safe area)
            kycWebView.topAnchor.constraint(equalTo: view.topAnchor),
            
            // Bottom to bottom of view with padding
            kycWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -70),
            
            // Center the activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable PIP at runtime as well (backup approach)
        if #available(iOS 14.2, *) {
            kycWebView.configuration.allowsPictureInPictureMediaPlayback = false
        }
        
        // Start loading animation
        activityIndicator.startAnimating()
        
        // Initialize managers
        setupWebViewComponents()
        
        // Configure UI
        hideBackButton()
        addSwipeGesture()
        
        // Set up app state notification
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(handleAppDidBecomeActive),
                                              name: UIApplication.didBecomeActiveNotification,
                                              object: nil)
        
        // Add error handling for the web view
        kycWebView.navigationDelegate = self
        kycWebView.uiDelegate = self
        
        // Set a timeout for loading
        setupLoadingTimeout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Ensure navigation bar is hidden when returning to this view
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Clean up web view
        kycWebView.stopLoading()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        // No manual adjustments needed - let the system handle it with contentInsetAdjustmentBehavior
    }
    
    deinit {
        // Remove observers
        NotificationCenter.default.removeObserver(self)
        
        // Clean up web view to prevent memory leaks
        kycWebView.stopLoading()
        kycWebView.navigationDelegate = nil
        kycWebView.uiDelegate = nil
    }
    
    // MARK: - Private Methods
    
    private func setupWebViewComponents() {
        // Create and configure web view manager
        webViewManager = WebViewManager(webView: kycWebView)
        
        // Create and configure JS bridge handler - using original parameter list
        jsBridgeHandler = JSBridgeHandler(
            webView: kycWebView,
            accessToken: accessToken,
            delegate: responseDelegate,
            viewController: self
        )
        
        // Configure the web view
        webViewManager.configure(delegate: self, uiDelegate: self, scriptHandler: jsBridgeHandler)
        
        // Load the URL
        loadWebViewContent()
    }
    
    private func loadWebViewContent() {
        // Validate URL before loading
        guard !url.isEmpty, let _ = URL(string: url) else {
            handleInvalidURL()
            return
        }
        
        // Load the URL in the web view
        webViewManager.load(url: url)
    }
    
    private func handleInvalidURL() {
        // Handle invalid URL scenario
        let errorResponse = CFErrorResponse()
        errorResponse.message = "Invalid URL provided"
        responseDelegate.onErrorResponse(errorReponse: errorResponse)
        
        // Go back to previous screen
        DispatchQueue.main.async { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }
    
    private func setupLoadingTimeout() {
        // Set timeout for loading (e.g., 30 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            guard let self = self else { return }
            
            // Check if we're still loading
            if self.activityIndicator.isAnimating {
                // Handle timeout
                self.handleLoadingTimeout()
            }
        }
    }
    
    private func handleLoadingTimeout() {
        // Show alert to user
        let alert = UIAlertController(
            title: "Connection Timeout",
            message: "The verification service is taking too long to respond. Would you like to retry?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.loadWebViewContent()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            guard let self = self else { return }
            // Go back and notify delegate of error
            self.navigationController?.popViewController(animated: true)
            let errorResponse = CFErrorResponse()
            errorResponse.message = "Connection timeout"
            self.responseDelegate.onErrorResponse(errorReponse: errorResponse)
        })
        
        present(alert, animated: true)
    }
    
    private func hideBackButton() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationItem.hidesBackButton = true
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
        let alert = UIAlertController(
            title: "Warning",
            message: "Are you sure you want to cancel the verification?",
            preferredStyle: .alert
        )
        
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
            
            // Check webview state and reload if needed
            self.kycWebView.evaluateJavaScript("document.readyState") { [weak self] result, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error checking readyState: \(error.localizedDescription)")
                    self.webViewManager.load(url: self.url)
                    return
                }
                
                if let state = result as? String, state != "complete" {
                    print("WebView not fully loaded. Reloading URL...")
                    self.webViewManager.load(url: self.url)
                } else {
                    print("WebView still active, no reload needed.")
                }
            }
        }
    }
    
    // Helper method to fix content size issues
    private func applyContentSizeFixesToWebView() {
        // Much simpler CSS - just add padding to the bottom of the page
        let js = """
        var style = document.createElement('style');
        style.textContent = 'body { width: 100%; height: auto; margin: 0; padding: 0 0 70px 0; overflow-x: hidden; } html { overflow-x: hidden; }';
        document.getElementsByTagName('head')[0].appendChild(style);
        """
        kycWebView.evaluateJavaScript(js, completionHandler: nil)
        
        // Ensure content fits width
        kycWebView.evaluateJavaScript("document.documentElement.scrollWidth") { [weak self] (width, error) in
            guard let self = self, let contentWidth = width as? CGFloat else { return }
            
            if contentWidth > self.kycWebView.frame.size.width {
                let zoom = self.kycWebView.frame.size.width / contentWidth
                self.kycWebView.evaluateJavaScript("document.documentElement.style.zoom = \(zoom)", completionHandler: nil)
            }
        }
    }
}

// MARK: - WKNavigationDelegate & WKUIDelegate
extension CFKycVerificationViewController: WKNavigationDelegate, WKUIDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicator.startAnimating()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        
        // Apply fixes for content size issues
        applyContentSizeFixesToWebView()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        handleWebViewError(error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        handleWebViewError(error)
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        print("WKWebView content process terminated, reloading...")
        activityIndicator.startAnimating()
        webViewManager.load(url: url)
    }
    
    private func handleWebViewError(_ error: Error) {
        // Skip handling for cancelled requests
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            return
        }
        
        // Handle connection errors
        if nsError.domain == NSURLErrorDomain &&
           (nsError.code == NSURLErrorNotConnectedToInternet ||
            nsError.code == NSURLErrorNetworkConnectionLost) {
            
            let alert = UIAlertController(
                title: "Connection Error",
                message: "Please check your internet connection and try again.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.webViewManager.load(url: self.url)
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
                guard let self = self else { return }
                self.navigationController?.popViewController(animated: true)
                let errorResponse = CFErrorResponse()
                errorResponse.message = "Network error: \(error.localizedDescription)"
                self.responseDelegate.onErrorResponse(errorReponse: errorResponse)
            })
            
            present(alert, animated: true)
        }
    }
    
    // Handle JavaScript alerts, confirms, prompts
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler()
        })
        present(alert, animated: true)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(false)
        })
        present(alert, animated: true)
    }
}
