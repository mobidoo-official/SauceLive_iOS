import UIKit
import WebKit
import SauceLive_iOS

class SauceViewController: SauceLiveViewController {
    var urlString = String()
    var handlerStates: [MessageHandlerName: Bool] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let config = SauceViewControllerConfig(
            isEnterEnabled: handlerStates[.enter] ?? false,
            isExitEnabled: handlerStates[.exit] ?? false,
            isLoginEnabled: handlerStates[.onLogin] ?? false,
            isProductEnabled: handlerStates[.onProduct] ?? false,
            isBannerEnabled: handlerStates[.onBanner] ?? false,
            isShareEnabled: handlerStates[.onShare] ?? false,
            isPictureInPictureEnabled: handlerStates[.onPictureInPicture] ?? false,
            isReloadingEnabled: handlerStates[.onReloading] ?? false,
            isRewardEnabled: handlerStates[.onReward] ?? false,
            isPIPActive: false,
            pipSize: CGSize(width: 150, height: 200),
            pipMode: .internalMode,
            delegate: self
        )
        configure(with: config)
        
        let sauceLiveLib = SauceLiveLib()
        sauceLiveLib.viewController = self
        sauceLiveLib.setInit(urlString)
        sauceLiveLib.setMemberObject(
            memberId: "멤버ID",
            nickName: "닉네임",
            age: "나이",
            gender: "성별") { success, error in
                if success {
                    sauceLiveLib.load()
                } else {
                    sauceLiveLib.load() // 게스트 로그인
                    print(error?.localizedDescription ?? "An unknown error occurred")
                }
            };
    }
}

// SauceLiveDelegate 프로토콜 채택 및 구현
extension SauceViewController: SauceLiveDelegate {
    func sauceLiveView(_ manager: SauceLiveViewController, setOnEnterListener message: WKScriptMessage) {
        print("enter")
    }
    
    func sauceLiveView(_ manager: SauceLiveViewController, setOnMoveExitListener message: WKScriptMessage) {
        print("exit")
    }
    
    func sauceLiveView(_ manager: SauceLiveViewController, setOnShareListener message: WKScriptMessage) {
        print("share")
    }
}
