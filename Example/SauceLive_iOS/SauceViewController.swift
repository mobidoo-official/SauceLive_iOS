import UIKit
import WebKit
import SauceLive_iOS

class SauceViewController: SauceLiveViewController {
    var urlString = String()
    var handlerStates: [MessageHandlerName: Bool] = [:]
    override func viewDidLoad() {
        super.viewDidLoad()
        //  urlString = "https://refactor.player.sauceflex.com/broadcast/lkuiux-a5acf6ee5d024d10b41b6391575b2cd0?"
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
            pipMode: .externalMode,
            delegate: self
        )
        configure(with: config)
        
        let sauceLiveLib = SauceLiveLib()
        sauceLiveLib.setInit(broadcastId: "'방송ID 를 입력해주세요")
        sauceLiveLib.setMemberObject(
           memberId: "string",
           nickName: "string",
           age: "string",
           gender: "string"
          );
        sauceLiveLib.load()
        
        let paymentDic: [String: Any] = [
            "orderCallBackId": "",
            "orderId": "",
            "payClickTime": "",
            "productQuantity": "",
            "amount": "",
            "memberId": ""
        ]
        createPayment(paymentData: paymentDic){ success, error in
            if success {
            } else if let error = error {
                print(error.localizedDescription)
            } else {
                
            }
        }
        
        
        var paymentDatas: [[String: Any]] = []
        paymentDatas.append(paymentDic)
        
        createPayments(paymentData: paymentDatas) { success, error in
            if success {
            } else if let error = error {
                print(error.localizedDescription)
            } else {
                
            }
        }
    }
}

// SauceLiveDelegate 프로토콜 채택 및 구현
extension SauceViewController: SauceLiveDelegate {
    func sauceLiveManager(_ manager: SauceLiveViewController, didReceiveEnterMessage message: WKScriptMessage) {
        print("enter")
    }
    
    func sauceLiveManager(_ manager: SauceLiveViewController, didReceiveMoveExitMessage message: WKScriptMessage) {
        PIPKit.dismiss(animated: true)
        print("exit")
    }
    
    func sauceLiveManager(_ manager: SauceLiveViewController, didReceivePictureInPictureMessage message: WKScriptMessage) {
        print("pip")
    }
}
