import Foundation
import UIKit
import AVKit
import WebKit

public enum MessageHandlerName: String {
    case enter = "sauceflexEnter"
    case moveExit = "sauceflexMoveExit"
    case moveLogin = "sauceflexMoveLogin"
    case moveProduct = "sauceflexMoveProduct"
    case moveBanner = "sauceflexMoveBanner"
    case onShare = "sauceflexOnShare"
    case onMoveReward = "sauceflexMoveReward"
    case pictureInPicture = "sauceflexPictureInPicture"
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

// SauceLiveManager 프로토콜 추가
protocol SauceLiveManager: AnyObject {
    func configure(with config: SauceViewControllerConfig)
    func loadURL(_ urlString: String)
    func startPictureInPicture()
    func stopPictureInPicture()
}

public struct SauceViewControllerConfig {
    public let url: String
    public let isEnterEnabled: Bool
    public let isMoveExitEnabled: Bool
    public let isMoveLoginEnabled: Bool
    public let isMoveProductEnabled: Bool
    public let isMoveBannerEnabled: Bool
    public let isOnShareEnabled: Bool
    public let isPictureInPictureEnabled: Bool
    public let isPIPAcive: Bool
    public let isPIPSize: CGSize
    public weak var delegate: SauceLiveDelegate? // Delegate 추가
    
    public init(url: String,
                isEnterEnabled: Bool? = false,
                isMoveExitEnabled: Bool? = false,
                isMoveLoginEnabled: Bool? = false,
                isMoveProductEnabled: Bool? = false,
                isMoveBannerEnabled: Bool? = false,
                isOnShareEnabled: Bool? = false,
                isPictureInPictureEnabled: Bool? = false,
                isPIPAcive: Bool? = false,
                isPIPSize: CGSize,
                delegate: SauceLiveDelegate?) {
        
        self.url = url
        self.isEnterEnabled = isEnterEnabled ?? false
        self.isMoveExitEnabled = isMoveExitEnabled ?? false
        self.isMoveLoginEnabled = isMoveLoginEnabled ?? false
        self.isMoveProductEnabled = isMoveProductEnabled ?? false
        self.isMoveBannerEnabled = isMoveBannerEnabled ?? false
        self.isOnShareEnabled = isOnShareEnabled ?? false
        self.isPictureInPictureEnabled = isPictureInPictureEnabled ?? false
        self.isPIPAcive = isPIPAcive ?? false
        self.isPIPSize = isPIPSize
        self.delegate = delegate
    }
}



open class SauceLiveViewController: UIViewController, WKScriptMessageHandler, AVPictureInPictureControllerDelegate, SauceLiveManager {
    
    public var webView: WKWebView!
    private var contentController = WKUserContentController()
    public weak var delegate: SauceLiveDelegate?
    public var messageHandlerNames: [MessageHandlerName] = []
    public var pipSize: CGSize = CGSize(width: 100, height: 200)
    
    private var leftButton: UIButton!
    private var rightButton: UIButton!
    
    public var url: String?
    
    public var pipController: AVPictureInPictureController?
    
    
    open override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // 구성 객체를 사용하여 SauceLiveViewController 설정
    public func configure(with config: SauceViewControllerConfig) {
        configureWebView()
        setupWebViewLayout()
        setupButtons()
        if config.isPIPAcive {
            self.view.isHidden = true
            openPIPView()
        }
        self.url = config.url
        self.delegate = config.delegate
        pipSize = config.isPIPSize
        // Additional configuration based on the provided config
        configureMessageHandlers(with: config)
        if let url = self.url {
            self.loadURL(url)
        }
    }
    
    public func loadURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    private func configureMessageHandlers(with config: SauceViewControllerConfig) {
        var handlers = [MessageHandlerName]()
        if config.isEnterEnabled { handlers.append(.enter) }
        if config.isMoveExitEnabled { handlers.append(.moveExit) }
        if config.isMoveLoginEnabled { handlers.append(.moveLogin) }
        if config.isMoveProductEnabled { handlers.append(.moveProduct) }
        if config.isMoveBannerEnabled { handlers.append(.moveBanner) }
        if config.isOnShareEnabled { handlers.append(.onShare) }
        if config.isPictureInPictureEnabled { handlers.append(.pictureInPicture) }
        self.messageHandlerNames = handlers
        registerMessageHandlers()
    }
    
    private func registerMessageHandlers() {
        contentController.removeAllUserScripts()
        messageHandlerNames.forEach { name in
            contentController.add(self, name: name.rawValue)
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
        
        view.addSubview(leftButton)
        view.addSubview(rightButton)
        
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
                self.stopPictureInPicture()
            }
        }
    }
    
    private func openPIPView() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
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
        rightButton.isHidden = false
        leftButton.isHidden = false
        webView.isUserInteractionEnabled = false
        PIPKit.startPIPMode()
        
    }
    
    public func stopPictureInPicture() {
        rightButton.isHidden = true
        leftButton.isHidden = true
        webView.isUserInteractionEnabled = true
        PIPKit.stopPIPMode()
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case MessageHandlerName.enter.rawValue:
            delegate?.sauceLiveManager?(self, didReceiveEnterMessage: message)
            playVideoInPictureInPictureMode(urlString: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")
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
            pipController?.startPictureInPicture()
           
            //startPictureInPicture()
        default:
            break
        }
    }
    
    func playVideoInPictureInPictureMode(urlString: String) {
        guard let url = URL(string: urlString) else {
            print("Invalid video URL")
            return
        }
        
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = CGRect(x: 0, y: 0, width: 300, height: 150) // Adjust frame as per your requirement
        
        let pipViewController = AVPlayerViewController()
        pipViewController.player = player
        addChild(pipViewController)
        view.addSubview(pipViewController.view)
        pipController = AVPictureInPictureController(playerLayer: playerLayer)
        pipController?.delegate = self
    }
}

// MARK: - WKNavigationDelegate
extension SauceLiveViewController: WKNavigationDelegate {
    // Handle navigation delegate methods if needed
}

// MARK: - WKUIDelegate
extension SauceLiveViewController: WKUIDelegate {
    // Handle UI delegate methods if needed
}

// MARK: - PIPUsable
extension SauceLiveViewController: PIPUsable {
    public var initialState: PIPState { return .full }
}

extension SauceLiveViewController {
    // MARK: - AVPictureInPictureControllerDelegate
    
    public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        // PiP mode ended
        print("Picture in Picture mode ended.")
    }
    
    public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        // PiP mode started
        print("Picture in Picture mode started.")
    }
    
    public func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        // PiP mode will end
        print("Picture in Picture mode will end.")
    }
    
    public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        // PiP mode will start
        print("Picture in Picture mode will start.")
    }
}

