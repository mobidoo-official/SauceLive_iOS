import Foundation

struct APIEnvironment {
    enum Environment: String {
        case development = "Development"
        case staging = "Staging"
        case production = "Production"
    }

    static var buildEnvironment: Environment = .production

    // 현재 환경에 맞는 API 호스트 URL을 반환하는 정적 프로퍼티
    static var current: String {
        switch buildEnvironment {
        case .development:
            return "https://dev.api.sauceFlex.com/V1"
        case .staging:
            return "https://stage.api.sauceFlex.com/V1"
        case .production:
            return "https://api.sauceFlex.com/V1"
        }
    }
}

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

public class APIService {
    static let shared = APIService()
    
    private init() {}
    
    public func fetchData(from urlString: String, parameters: Data? = nil, method: HTTPMethod = .get, success: @escaping (Data) -> Void, failure: @escaping (Error?) -> Void) {
        guard var urlComponents = URLComponents(string: urlString) else {
            print("Invalid URL")
            failure(nil)
            return
        }
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = method.rawValue
        
        // Content-Type 헤더를 추가합니다.
        if method != .get {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        // GET 메소드가 아닌 경우, 파라미터를 HTTP 바디에 추가합니다.
        if method != .get, let parameters = parameters {
            request.httpBody = parameters
        }
        
        // URLSession을 사용하여 데이터 태스크를 생성하고 실행합니다.
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                failure(error)
                return
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                if let data = data {
                    success(data)
                } else {
                    failure(nil)
                }
            default:
                failure(nil)
            }
        }
        
        task.resume()
    }
}

