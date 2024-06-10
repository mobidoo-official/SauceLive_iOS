import Foundation
import UIKit
import AVKit
import WebKit

public enum PIPMode {
    case internalMode
    case externalMode
}

public enum MessageHandlerName: String {
    case enter = "sauceflexEnter"
    case exit = "sauceflexMoveExit"
    case onLogin = "sauceflexMoveLogin"
    case onProduct = "sauceflexMoveProduct"
    case onBanner = "sauceflexMoveBanner"
    case onShare = "sauceflexOnShare"
    case onPictureInPicture = "sauceflexPictureInPicture"
    case onReloading = "sauceflexWebviewReloading"
    case onReward = "sauceflexMoveReward"
    case videoUrl = "sauceflexSendVideoUrl"
}

@objc public protocol SauceLiveDelegate: AnyObject {
    @objc optional func sauceLiveView(_ manager: SauceLiveViewController, setOnEnterListener message: WKScriptMessage)
    @objc optional func sauceLiveView(_ manager: SauceLiveViewController, setOnMoveExitListener message: WKScriptMessage)
    @objc optional func sauceLiveView(_ manager: SauceLiveViewController, setOnMoveLoginListener message: WKScriptMessage)
    @objc optional func sauceLiveView(_ manager: SauceLiveViewController, setOnShareListener message: WKScriptMessage)
    @objc optional func sauceLiveView(_ manager: SauceLiveViewController, setOnPictureInPictureListener message: WKScriptMessage)
    @objc optional func sauceLiveView(_ manager: SauceLiveViewController, setOnMoveBannerListener message: WKScriptMessage)
    @objc optional func sauceLiveView(_ manager: SauceLiveViewController, setOnWebviewReloadingListener message: WKScriptMessage)
    @objc optional func sauceLiveView(_ manager: SauceLiveViewController, setOnMoveRewardListener message: WKScriptMessage)
    @objc optional func sauceLiveView(_ manager: SauceLiveViewController, setOnMoveProductListener message: WKScriptMessage)
}

// SauceLiveManager 프로토콜 추가
protocol SauceLiveManager: AnyObject {
    func configure(with config: SauceViewControllerConfig)
    func loadURL(_ urlString: String)
    func startPictureInPicture()
    func stopPictureInPicture()
}

public struct SauceViewControllerConfig {
    public let isEnterEnabled: Bool
    public let isExitEnabled: Bool
    public let isLoginEnabled: Bool
    public let isProductEnabled: Bool
    public let isBannerEnabled: Bool
    public let isShareEnabled: Bool
    public let isPictureInPictureEnabled: Bool
    public let isReloadingEnabled: Bool
    public let isRewardEnabled: Bool
    public let isPIPActive: Bool
    
    public let pipSize: CGSize
    public let pipMode: PIPMode
    public weak var delegate: SauceLiveDelegate? // Delegate 추가
    public init(isEnterEnabled: Bool? = false,
                isExitEnabled: Bool? = false,
                isLoginEnabled: Bool? = false,
                isProductEnabled: Bool? = false,
                isBannerEnabled: Bool? = false,
                isShareEnabled: Bool? = false,
                isPictureInPictureEnabled: Bool? = false,
                isReloadingEnabled: Bool? = false,
                isRewardEnabled: Bool? = false,
                isPIPActive: Bool? = false,
                pipSize: CGSize,
                pipMode: PIPMode = .internalMode,
                delegate: SauceLiveDelegate?) {
        self.isEnterEnabled = isEnterEnabled ?? false
        self.isExitEnabled = isExitEnabled ?? false
        self.isLoginEnabled = isLoginEnabled ?? false
        self.isProductEnabled = isProductEnabled ?? false
        self.isBannerEnabled = isBannerEnabled ?? false
        self.isShareEnabled = isShareEnabled ?? false
        self.isPictureInPictureEnabled = isPictureInPictureEnabled ?? false
        self.isReloadingEnabled = isReloadingEnabled ?? false
        self.isRewardEnabled = isRewardEnabled ?? false
        self.isPIPActive = isPIPActive ?? false
        self.pipSize = pipSize
        self.pipMode = pipMode
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
    public var player: AVPlayer?
    public var playerLayer: AVPlayerLayer?
    
    var fullScreen: Bool = false
    var originalViewSize: CGSize = .zero
    var globalStartTime = CMTime(seconds: 0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    
    private var pipMode: PIPMode = .internalMode
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        originalViewSize = self.view.frame.size
    }
    
    // 구성 객체를 사용하여 SauceLiveViewController 설정
    public func configure(with config: SauceViewControllerConfig) {
        configureWebView()
        setupWebViewLayout()
        setupButtons()
        self.delegate = config.delegate
        self.pipMode = config.pipMode
        pipSize = config.pipSize

        configureMessageHandlers(with: config)
        
        if config.isPIPActive {
            self.view.isHidden = true
            openPIPView()
        }
    }
    
    public func loadURL(_ urlString: String) {
        print(urlString)
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    private func configureMessageHandlers(with config: SauceViewControllerConfig) {
        var handlers = [MessageHandlerName]()
        handlers.append(.videoUrl)
        
        if config.isEnterEnabled { handlers.append(.enter) }
        if config.isExitEnabled { handlers.append(.exit) }
        if config.isLoginEnabled { handlers.append(.onLogin) }
        if config.isProductEnabled { handlers.append(.onProduct) }
        if config.isBannerEnabled { handlers.append(.onBanner) }
        if config.isShareEnabled { handlers.append(.onShare) }
        if config.isPictureInPictureEnabled { handlers.append(.onPictureInPicture) }
        if config.isReloadingEnabled { handlers.append(.onReloading) }
        if config.isRewardEnabled { handlers.append(.onReward) }
        
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
        
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        } else {
            // Fallback on earlier versions
        }
        
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
            let name = "window.dispatchEvent(sauceflexPictureInPictureOn);"
            self.webView.evaluateJavaScript(name) { (Result, Error) in
                if let error = Error {
                    print("evaluateJavaScript Error : \(error)")
                }
            }
            self.startPictureInPicture()
            self.view.isHidden = false
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
        case MessageHandlerName.videoUrl.rawValue:
            if self.pipMode == .externalMode {
                let jsonString = "\(message.body)"
                if let jsonData = jsonString.data(using: .utf8) {
                    do {
                        if let jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                            if let urlString = jsonDict["videoUrl"] as? String, url != "null" {
                                guard let url = URL(string: urlString) else {
                                    print("Invalid video URL")
                                    return
                                }
                                player = AVPlayer(url: url)
                                playerLayer = AVPlayerLayer(player: player)
                                playVideoInPictureInPictureMode()
                            } else {
                                print("videoUrl 키에 해당하는 Url 값이 없습니다.")
                            }
                        }
                    } catch {
                        print("JSON 파싱 중 에러 발생: \(error)")
                    }
                }
            }
        case MessageHandlerName.enter.rawValue:
            delegate?.sauceLiveView?(self, setOnEnterListener: message)
        case MessageHandlerName.exit.rawValue:
            delegate?.sauceLiveView?(self, setOnMoveExitListener: message)
        case MessageHandlerName.onLogin.rawValue:
            delegate?.sauceLiveView?(self, setOnMoveLoginListener: message)
        case MessageHandlerName.onShare.rawValue:
            delegate?.sauceLiveView?(self, setOnShareListener: message)
        case MessageHandlerName.onPictureInPicture.rawValue:
            delegate?.sauceLiveView?(self, setOnPictureInPictureListener: message)
            if self.pipMode == .externalMode {
                let jsonString = "\(message.body)"
                if let jsonData = jsonString.data(using: .utf8) {
                    do {
                        if let jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                            if let currentTime = jsonDict["currentTime"] as? Double, currentTime != -1 {
                                globalStartTime = CMTime(seconds: currentTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                            } else {
                                print("currentTime 키에 해당하는 Double 값이 없습니다.")
                            }
                            
                            if let playerLayer = playerLayer {
                                self.view.frame.size = .zero
                                view.layer.addSublayer(playerLayer)
                                pipController?.startPictureInPicture()
                                pipController?.playerLayer.frame.size = .zero
                            } else {
                                startPictureInPicture()
                            }
                           
                        }
                    } catch {
                        print("JSON 파싱 중 에러 발생: \(error)")
                    }
                }
                
            } else {
                startPictureInPicture()
            }
        case MessageHandlerName.onBanner.rawValue:
            delegate?.sauceLiveView?(self, setOnMoveBannerListener: message)
            
        case MessageHandlerName.onReloading.rawValue:
            delegate?.sauceLiveView?(self, setOnWebviewReloadingListener: message)
            
        case MessageHandlerName.onReward.rawValue:
            delegate?.sauceLiveView?(self, setOnMoveRewardListener: message)
            
        case MessageHandlerName.onProduct.rawValue:
            delegate?.sauceLiveView?(self, setOnMoveProductListener: message)
        default:
            break
        }
    }
    
    func playVideoInPictureInPictureMode() {
        guard let playerLayer = playerLayer else { return }
        playerLayer.frame = view.bounds // 비디오 플레이어의 크기를 설정합니다.
        // AVPictureInPictureController가 사용 가능한지 확인합니다.
        if AVPictureInPictureController.isPictureInPictureSupported() {
            pipController = AVPictureInPictureController(playerLayer: playerLayer)
            pipController?.delegate = self
        }
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
        if fullScreen {
            DispatchQueue.main.async {
                self.view.frame.size = self.originalViewSize
                self.playerLayer?.removeFromSuperlayer()
                self.pipController?.playerLayer.frame.size = self.originalViewSize
                let name = "window.dispatchEvent(sauceFlexPIP(false));"
                self.webView.evaluateJavaScript(name) { (Result, Error) in
                    if let error = Error {
                        print("evaluateJavaScript Error : \(error)")
                    } else {
    
                    }
                }
                let currentSeconds = CMTimeGetSeconds(self.globalStartTime )
                let seekTime = "dispatchEvent(window.sauceflexPictureInPictureExit(\(Int(currentSeconds))))"
                self.webView.evaluateJavaScript(seekTime) { (Result, Error) in
                    if let error = Error {
                        print("evaluateJavaScript Error : \(error)")
                    } else {
                    }
                }
                self.fullScreen = false
            }
            
        } else {
            self.dismiss(animated: false)
        }
    }
    
    public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
         print("Picture in Picture mode started.")
        let time = globalStartTime
        player?.seek(to: time, completionHandler: { (completedSeek) in
            if completedSeek {
                self.player?.play()
            }
        })
    }
    
    public func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        // PiP mode will end
        print("Picture in Picture mode will end.")
        
        
    }
    
    public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        // PiP mode will start
        print("Picture in Picture mode will start.")
    }
    
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        print("restore")
        fullScreen = true
        if let currentTime = player?.currentTime() {
            globalStartTime =  currentTime
        } else {
            globalStartTime = CMTime(seconds: 0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        }
        completionHandler(true)
    }
}

extension SauceLiveViewController {
   public func createPayment(paymentData: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
            PaymentManager.shared.createPayment(with: paymentData, completion: completion)
    }
    
    public func createPaymentListTracker(paymentData: [[String: Any]], completion: @escaping (Bool, Error?) -> Void) {
             PaymentManager.shared.createPayments(with: paymentData, completion: completion)
     }
    
    public func updatePaymentTracker(paymentData: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
             PaymentManager.shared.editPayment(with: paymentData, completion: completion)
     }
    
    public func deletePaymentTracker(paymentData: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
             PaymentManager.shared.removePayment(with: paymentData, completion: completion)
     }
}

