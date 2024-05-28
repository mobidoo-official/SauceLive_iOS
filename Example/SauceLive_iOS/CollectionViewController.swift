import UIKit
import WebKit
import SauceLive_iOS

class CollectionViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let (customWebView, heightConstraint) = CollectionWebView.createWebView(type: .topBanner)
        self.view.addSubview(customWebView)
        
        // 오토레이아웃 제약 조건 설정
        NSLayoutConstraint.activate([
            customWebView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            customWebView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            customWebView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            heightConstraint
        ])
    }
}
