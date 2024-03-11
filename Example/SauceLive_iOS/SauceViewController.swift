import UIKit
import WebKit
import SauceLive_iOS

class SauceViewController: SauceLiveViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
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
