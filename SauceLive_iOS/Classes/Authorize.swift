//
//  Authorize.swift
//  Pods-SauceLive_iOS_Example
//
//  Created by 김원철 on 3/28/24.
//

import Foundation

// 회원 정보 구조체
struct MemberResponse: Codable {
    let code: String
    let timestamp: Int64
    let requestId: String
    let message: String
    let response: MemberInfo
}
struct MemberInfo: Codable {
    let accessToken: String
    let partnerId: String
    let memberId: String
    let nickName: String
    let age: String
    let gender: String
    let memberType: String
}

public class SauceLiveLib {
    public init() {}

    var broadcastId: String?
    var accessToken: String?
    var partnerId: String?
    
    public weak var viewController: SauceLiveViewController?
    
    // 방송 ID 설정
    public func setInit(_ broadcastId: String) {
        self.broadcastId = broadcastId
        let pattern = "(lk|vc|vk)(.*-?)-"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsRange = NSRange(broadcastId.startIndex..<broadcastId.endIndex, in: broadcastId)
            if let match = regex.firstMatch(in: broadcastId, options: [], range: nsRange) {
                if match.numberOfRanges > 2 {
                    let range = match.range(at: 2)
                    if range.location != NSNotFound, let swiftRange = Range(range, in: broadcastId) {
                        let matchedString = String(broadcastId[swiftRange])
                        self.partnerId = matchedString
                    }
                }
            }
        } catch {
            print("정규식 오류: \(error.localizedDescription)")
        }
    }
    
    public func setStageMode(on: Bool) {
        if on {
            APIEnvironment.buildEnvironment = .staging
        } else {
            APIEnvironment.buildEnvironment = .production
        }
        
    }
    
    public func setMemberToken(_ token : String) {
        self.accessToken = token
    }
    
    // 멤버 객체 설정
    public func setMemberObject(memberId: String, nickName: String, age: String? = nil, gender: String? = nil, completion: @escaping () -> Void) {
        let paymentDic: [String: Any] = [
            "partnerId": self.partnerId ?? "",
            "memberId": memberId,
            "nickName": nickName,
            "age": age ?? "ect",
            "gender": gender ?? "e",
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: paymentDic, options: [])
        let url = APIEnvironment.current + "/internal/token"
        APIService.shared.fetchData(from: url, parameters: jsonData, method: .post) { data in
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(MemberResponse.self, from: data)
                self.accessToken = response.response.accessToken
                completion()
            } catch {
                completion()
            }
        } failure: { error in
            print(error?.localizedDescription ?? "An unknown error occurred")
            completion()
        }
    }
    
    public func moveUrlTarget() {
        let host = APIEnvironment.player
        if let id = broadcastId, let token = accessToken {
            let urlString = host + "/broadcast/\(id)?accessToken=\(token)"
            DispatchQueue.main.async {
                print(urlString)
                self.viewController?.loadURL(urlString)
            }
        }
        else if let id = broadcastId {
            let urlString = host + "/broadcast/\(id)"
            DispatchQueue.main.async {
                self.viewController?.loadURL(urlString)
            }
        }
        else {
            print("Broadcast ID와 Access Token 둘 다 없습니다.")
        }
    }
}
