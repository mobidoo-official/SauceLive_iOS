import Foundation
import UIKit
import WebKit

public enum PiPExecutionMode {
    case internalPiP
    case externalPiP
}

public enum MessageHandlerName: String {
    case customCoupon = "sauceflexSetCustomCoupon"
    case issueCoupon = "sauceflexIssueCoupon"
    case enter = "sauceflexEnter"
    case moveExit = "sauceflexMoveExit"
    case moveLogin = "sauceflexMoveLogin"
    case moveProduct = "sauceflexMoveProduct"
    case moveBanner = "sauceflexMoveBanner"
    case onShare = "sauceflexOnShare"
    case pictureInPicture = "sauceflexPictureInPicture"
    case sauceflexOSPictureInPicture = "sauceflexOSPictureInPicture"
   // case tokenError = "sauceflexTokenError"
   // case pictureInPictureOn = "sauceflexPictureInPictureOn"
}

@objc public protocol SauceLiveDelegate: AnyObject {
    @objc optional func sauceLiveManager(_ manager: SauceLiveViewController, didReceiveCustomCouponMessage message: WKScriptMessage)
    @objc optional func sauceLiveManager(_ manager: SauceLiveViewController, didReceiveIssueCouponMessage message: WKScriptMessage)
    @objc optional func sauceLiveManager(_ manager: SauceLiveViewController, didReceiveEnterMessage message: WKScriptMessage)
    @objc optional func sauceLiveManager(_ manager: SauceLiveViewController, didReceiveMoveExitMessage message: WKScriptMessage)
    @objc optional func sauceLiveManager(_ manager: SauceLiveViewController, didReceiveMoveLoginMessage message: WKScriptMessage)
    @objc optional func sauceLiveManager(_ manager: SauceLiveViewController, didReceiveMoveProductMessage message: WKScriptMessage)
    @objc optional func sauceLiveManager(_ manager: SauceLiveViewController, didReceiveMoveBannerMessage message: WKScriptMessage)
    @objc optional func sauceLiveManager(_ manager: SauceLiveViewController, didReceiveOnShareMessage message: WKScriptMessage)
}

open class SauceLiveViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
    public var webView: WKWebView!
    var contentController = WKUserContentController()
    private var leftButton: UIButton!
    private var rightButton: UIButton!
    public weak var delegate: SauceLiveDelegate?
    public var messageHandlerNames: [MessageHandlerName] = [] {
        didSet {
            registerMessageHandlers()
        }
    }
    
    public var pipSize: CGSize = CGSize(width: 100, height: 200)
    public var pipExecutionMode: PiPExecutionMode = .internalPiP
    public var openPIP: Bool = false
    
    var webViewWidthConstraint: NSLayoutConstraint?
    var webViewHeightConstraint: NSLayoutConstraint?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        if pipExecutionMode == .externalPiP {
            NotificationCenter.default.addObserver(self, selector: #selector(handleAppDidEnterBackground), name: NSNotification.Name("AppDidEnterBackground"), object: nil)
        }
        
        configureWebView()
        setupWebViewLayout()
        setupButtons()
        if openPIP {
            openPIPView()
        }
    }
    
    @objc private func handleAppDidEnterBackground() {
        if pipExecutionMode == .externalPiP {
            PIPKit.stopPIPMode()
            self.view.isHidden = false
            self.view.isUserInteractionEnabled = false
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                // 1초 후 실행될 부분
                // PiP 영상 재생 스크립트 실행
                
                
                let script = """
        if (document.pictureInPictureElement) {
            document.pictureInPictureElement.play();
        }
        """
                self.webView.evaluateJavaScript(script) { result, error in
                    if let error = error {
                        print("JavaScript 실행 오류: \(error)")
                    }
                }
            }
        }
    }
    
    public func configureWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        configuration.allowsInlineMediaPlayback = true
        
        if #available(iOS 10.0, *) {
            configuration.mediaTypesRequiringUserActionForPlayback = []
        }
        configuration.userContentController = contentController
        configuration.allowsPictureInPictureMediaPlayback = true
        if #available(iOS 14.0, *) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            configuration.preferences.javaScriptEnabled = true
        }
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view.addSubview(webView)
    }
    
    public func loadURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    private func registerMessageHandlers() {
        for name in messageHandlerNames {
            contentController.add(self, name: name.rawValue)
        }
    }
    
    private func setupWebViewLayout() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setupButtons() {
        leftButton = UIButton(type: .custom)
        rightButton = UIButton(type: .custom)
        
        guard let bundleURL = Bundle(for: SauceLiveViewController.self).url(forResource: "assets", withExtension: "bundle"),
              let bundle = Bundle(url: bundleURL) else {
            return
        }
        
        let closeImage = UIImage(named: "CloseButton", in: bundle, compatibleWith: nil)
        let pipImage = UIImage(named: "PIPButton", in: bundle, compatibleWith: nil)
        
        leftButton.setImage(closeImage, for: .normal)
        rightButton.setImage(pipImage, for: .normal)
        
        leftButton.addTarget(self, action: #selector(leftButtonTapped), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(rightButtonTapped), for: .touchUpInside)
        
        leftButton.isHidden = true
        rightButton.isHidden = true
        
        webView.addSubview(leftButton)
        webView.addSubview(rightButton)
        
        leftButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            leftButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            leftButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            rightButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            rightButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10)
        ])
    }
    
    
    // Left button event handler
    @objc open func leftButtonTapped() {
        PIPKit.dismiss(animated: true)
    }
    
    // Right button event handler
    @objc open func rightButtonTapped() {
        let name = "window.dispatchEvent(sauceFlexPIP(false));"
        webView.evaluateJavaScript(name) { (Result, Error) in
            if let error = Error {
                print("evaluateJavaScript Error : \(error)")
            } else {
                self.leftButton.isHidden = true
                self.rightButton.isHidden = true
                PIPKit.stopPIPMode()
            }
        }
    }
    
    public func cleanupForDismiss() {
        
        for name in messageHandlerNames {
            contentController.removeScriptMessageHandler(forName: name.rawValue)
        }
        
        // PiP 모드를 종료하는 스크립트 실행
        let script = "if (document.querySelector('video').webkitPresentationMode === 'picture-in-picture') { document.querySelector('video').webkitSetPresentationMode('inline'); }"
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("PiP 모드 종료 스크립트 실행 오류: \(error)")
            }
        }
    }
    
    private func videoPIP() {
        let script = """
            if (document.querySelector('video') && !document.querySelector('video').paused) {
                document.querySelector('video').webkitSetPresentationMode('picture-in-picture');
            }
            """
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    private func disableVideoPIP() {
        let name = "window.dispatchEvent(sauceFlexPIP(false));"
        webView.evaluateJavaScript(name) { (Result, Error) in
            if let error = Error {
                print("evaluateJavaScript Error : \(error)")
            }
        }
    }
    
    private func openPIPView() {
        pipExecutionMode = .internalPiP
        self.view.isHidden = true
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            self.startPictureInPicture()
            self.view.isHidden = false
            let name = "window.dispatchEvent(sauceflexPictureInPictureOn);"
            self.webView.evaluateJavaScript(name) { (Result, Error) in
                if let error = Error {
                    print("evaluateJavaScript Error : \(error)")
                }
            }
        }
    }
    
    public func startPictureInPicture() {
        if pipExecutionMode == .internalPiP {
            rightButton.isHidden = false
            leftButton.isHidden = false
            PIPKit.startPIPMode()
        } else {
            self.view.isHidden = true
            self.view.isUserInteractionEnabled = false
            pipSize = CGSize(width: 0, height: 0)
            PIPKit.startPIPMode()
            self.videoPIP()
        }
    }
    public func stopPictureInPicture() {
        if pipExecutionMode == .internalPiP {
            rightButton.isHidden = true
            leftButton.isHidden = true
            PIPKit.stopPIPMode()
        } else {
            self.view.isHidden = false
            self.view.isUserInteractionEnabled = true
            PIPKit.stopPIPMode()
            self.disableVideoPIP()
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                let script = """
        if (document.querySelector('video')) {
            document.querySelector('video').play();
        }
        """
                self.webView.evaluateJavaScript(script) { result, error in
                    if let error = error {
                        print("JavaScript 실행 오류: \(error)")
                    }
                }
                
            }
        }
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case MessageHandlerName.customCoupon.rawValue:
            delegate?.sauceLiveManager?(self, didReceiveCustomCouponMessage: message)
        case MessageHandlerName.issueCoupon.rawValue:
            delegate?.sauceLiveManager?(self, didReceiveIssueCouponMessage: message)
        case MessageHandlerName.enter.rawValue:
            delegate?.sauceLiveManager?(self, didReceiveEnterMessage: message)
        case MessageHandlerName.moveExit.rawValue:
            PIPKit.dismiss(animated: true)
            delegate?.sauceLiveManager?(self, didReceiveMoveExitMessage: message)
        case MessageHandlerName.moveLogin.rawValue:
            delegate?.sauceLiveManager?(self, didReceiveMoveLoginMessage: message)
        case MessageHandlerName.moveProduct.rawValue:
            delegate?.sauceLiveManager?(self, didReceiveMoveProductMessage: message)
        case MessageHandlerName.moveBanner.rawValue:
            delegate?.sauceLiveManager?(self, didReceiveMoveBannerMessage: message)
        case MessageHandlerName.onShare.rawValue:
            delegate?.sauceLiveManager?(self, didReceiveOnShareMessage: message)
        case MessageHandlerName.pictureInPicture.rawValue:
            startPictureInPicture()
        case MessageHandlerName.sauceflexOSPictureInPicture.rawValue:
            if let pipMessage = message.body as? String {
                if pipMessage == "true" {
                    
                } else {
                    stopPictureInPicture()
                }
            }
        default:
            break
        }
    }
}

extension SauceLiveViewController: PIPUsable {
    public var initialState: PIPState { return .full }
}
