//
//  Authorize.swift
//  Pods-SauceLive_iOS_Example
//
//  Created by 김원철 on 3/28/24.
//

import Foundation

public struct MemberObject {
    var memberId: String
    var nickName: String
    var age: String? // 옵셔널로 선언
    var gender: String? // 옵셔널로 선언
}

public class SauceLiveLib {
    public init() {}
    
    var broadcastId: String?
    var memberObject: MemberObject?
    
    // 방송 ID 설정
    public func setInit(broadcastId: String) {
        self.broadcastId = broadcastId
    }
    
    // 멤버 객체 설정
    public func setMemberObject(memberId: String, nickName: String, age: String? = nil, gender: String? = nil) {
        let member = MemberObject(memberId: memberId, nickName: nickName, age: age, gender: gender)
        self.memberObject = member
    }
    
    // 라이브러리 로드 및 처리 수행
    public func load() {
        guard let broadcastId = broadcastId, let memberObject = memberObject else {
            print("SauceLiveLib: Broadcast ID or Member Object not set.")
            return
        }
        print("SauceLiveLib Loaded with Broadcast ID: \(broadcastId) and Member ID: \(memberObject.memberId)")
    }
}
