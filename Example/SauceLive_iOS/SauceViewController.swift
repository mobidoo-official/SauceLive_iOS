import UIKit
import WebKit
import SauceLive_iOS

class SauceViewController: SauceLiveViewController {
    var urlString = String()
    var handlerStates: [MessageHandlerName: Bool] = [:]
    override func viewDidLoad() {
        super.viewDidLoad()

        let config = SauceViewControllerConfig(
                    url: urlString,
                    isEnterEnabled: handlerStates[.enter] ?? false,
                    isMoveExitEnabled: handlerStates[.moveExit] ?? false,
                    isMoveLoginEnabled: handlerStates[.moveLogin] ?? false,
                    isMoveProductEnabled: handlerStates[.moveProduct] ?? false,
                    isMoveBannerEnabled: handlerStates[.moveBanner] ?? false,
                    isOnShareEnabled: handlerStates[.onShare] ?? false,
                    isPictureInPictureEnabled: handlerStates[.pictureInPicture] ?? false,
                    isPIPAcive: false,
                    isPIPSize: CGSize(width: 300, height: 200),
                    delegate: self
                )
        configure(with: config)
    }
}

// SauceLiveDelegate 프로토콜 채택 및 구현
extension SauceViewController: SauceLiveDelegate {
    func sauceLiveManager(_ manager: SauceLiveViewController, didReceiveEnterMessage message: WKScriptMessage) {
        print("enter")
    }
    
    func sauceLiveManager(_ manager: SauceLiveViewController, didReceiveMoveExitMessage message: WKScriptMessage) {
        print("exit")
    }
    
    func sauceLiveManager(_ manager: SauceLiveViewController, didReceivePictureInPictureMessage message: WKScriptMessage) {
        print("pip")
    }
}
