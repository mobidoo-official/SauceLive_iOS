import WebKit
import UIKit

public enum WebViewType {
    case topBanner
    case broadcast
    case schedule
    case broadcastTable
    case curation
    case curationDetail
}

public class CollectionWebView {
    
    public static func createWebView(type: WebViewType) -> (webView: WKWebView, heightConstraint: NSLayoutConstraint) {
        let configuration = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        let heightConstraint = webView.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.isActive = true
        
        let handler = CommonMessageHandler(webView: webView, heightConstraint: heightConstraint)
        contentController.add(handler, name: "flexcollectSendDOMRect")
        
        // 타입별 브릿지 설정
        switch type {
        case .topBanner:
            configureBridgeTopBanner(contentController: contentController)
        case .broadcast:
            configureBridgeBroadcast(contentController: contentController)
        case .schedule:
            configureBridgeSchedule(contentController: contentController)
        case .broadcastTable:
            configureBridgeBroadcastTable(contentController: contentController)
        case .curation:
            configureBridgeCuration(contentController: contentController)
        case .curationDetail:
            configureBridgeCurationDetail(contentController: contentController)
        }
        
        configuration.userContentController = contentController
        
        // URL 로드
        if let url = getUrl(for: type) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return (webView, heightConstraint)
    }
    
    private static func getUrl(for type: WebViewType) -> URL? {
        switch type {
        case .topBanner:
            return URL(string: "https://example.com/topBanner")
        case .broadcast:
            return URL(string: "https://example.com/broadcast")
        case .schedule:
            return URL(string: "https://example.com/schedule")
        case .broadcastTable:
            return URL(string: "https://example.com/broadcastTable")
        case .curation:
            return URL(string: "https://example.com/curation")
        case .curationDetail:
            return URL(string: "https://example.com/curationDetail")
        }
    }
    
    private static func configureBridgeTopBanner(contentController: WKUserContentController) {
        // 추가 설정이 필요한 경우 여기에 작성
    }
    
    private static func configureBridgeBroadcast(contentController: WKUserContentController) {
        // 추가 설정이 필요한 경우 여기에 작성
    }
    
    private static func configureBridgeSchedule(contentController: WKUserContentController) {
        // 추가 설정이 필요한 경우 여기에 작성
    }
    
    private static func configureBridgeBroadcastTable(contentController: WKUserContentController) {
        // 추가 설정이 필요한 경우 여기에 작성
    }
    
    private static func configureBridgeCuration(contentController: WKUserContentController) {
        // 추가 설정이 필요한 경우 여기에 작성
    }
    
    private static func configureBridgeCurationDetail(contentController: WKUserContentController) {
        // 추가 설정이 필요한 경우 여기에 작성
    }
}


class CommonMessageHandler: NSObject, WKScriptMessageHandler {
    weak var webView: WKWebView?
    var heightConstraint: NSLayoutConstraint?

    init(webView: WKWebView, heightConstraint: NSLayoutConstraint) {
        self.webView = webView
        self.heightConstraint = heightConstraint
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "flexcollectSendDOMRect", let height = message.body as? CGFloat {
            updateWebViewHeight(height)
        }
    }

    private func updateWebViewHeight(_ height: CGFloat) {
        DispatchQueue.main.async {
            self.heightConstraint?.constant = height
            self.webView?.superview?.layoutIfNeeded()
        }
    }
}
