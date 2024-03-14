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
    public let pipMode: PIPMode
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
                pipMode: PIPMode = .internalMode,
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
        self.url = config.url
        self.delegate = config.delegate
        self.pipMode = config.pipMode
        pipSize = config.isPIPSize
        // Additional configuration based on the provided config
        configureMessageHandlers(with: config)
        if let url = self.url {
            self.loadURL(url)
        }
        if config.isPIPAcive {
            self.view.isHidden = true
            openPIPView()
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
        case MessageHandlerName.enter.rawValue:
            delegate?.sauceLiveManager?(self, didReceiveEnterMessage: message)
            if self.pipMode == .externalMode {
                playVideoInPictureInPictureMode(urlString: "https://stage-cdn.sauceflex.com/streams/20240312/lkyanolja-475b05e2f811461db5eb2eea3480378d/d1fb0c56168541d7b7cda567a6878dd7_VOD.m3u8")
            }
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
                            self.view.frame.size = .zero
                            view.layer.addSublayer(playerLayer!)
                            pipController?.startPictureInPicture()
                            pipController?.playerLayer.frame.size = .zero
                        }
                    } catch {
                        print("JSON 파싱 중 에러 발생: \(error)")
                    }
                }
                
            } else {
                startPictureInPicture()
            }
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
                let name = "window.dispatchEvent(sauceFlexPIP(false));"
                self.webView.evaluateJavaScript(name) { (Result, Error) in
                    if let error = Error {
                        print("evaluateJavaScript Error : \(error)")
                    } else {
    
                    }
                }
                let currentSeconds = CMTimeGetSeconds(self.globalStartTime )
                let seekTime = "dispatchEvent(window.sauceflexPictureInPictureExit(\(Int(currentSeconds))))"
                
                print(seekTime)
                self.webView.evaluateJavaScript(seekTime) { (Result, Error) in
                    if let error = Error {
                        print("evaluateJavaScript Error : \(error)")
                    } else {
                    }
                }
                self.fullScreen = false
                //pipController?.stopPictureInPicture()
            }
            
        } else {
            self.dismiss(animated: false)
        }
    }
    
    public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        // print("Picture in Picture mode started.")
        let time = globalStartTime
        // 지정한 시간으로 이동
        player?.seek(to: time, completionHandler: { (completedSeek) in
            // 이동 완료 후 재생 시작
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

