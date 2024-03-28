
import Foundation

final class PaymentManager {
    static let shared = PaymentManager()
    
    private init() {}
    
    func createPayment(with paymentData: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        
        let url = APIEnvironment.current + "/front/product/payment"
        let jsonData = try? JSONSerialization.data(withJSONObject: paymentData, options: [])
        APIService.shared.fetchData(from: url, parameters: jsonData, method: .get) { data in
            completion(true, nil)
        } failure: { error in
            completion(false, error)
        }
    }
    
    func createPayments(with paymentDatas: [[String: Any]], completion: @escaping (Bool, Error?) -> Void) {
      
        
        let url = APIEnvironment.current + "/front/product/payments"
        let jsonData = try? JSONSerialization.data(withJSONObject: paymentDatas, options: [])
        
        APIService.shared.fetchData(from: url, parameters: jsonData, method: .post) { data in
            completion(true, nil)
        } failure: { error in
            completion(false, error)
        }
    }
    
        func editPayment(with paymentData: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
            let url = APIEnvironment.current + "/front/product/payment"
            let jsonData = try? JSONSerialization.data(withJSONObject: paymentData, options: [])
            APIService.shared.fetchData(from: url, parameters: jsonData, method: .patch) { data in
                completion(true, nil)
            } failure: { error in
                completion(false, error)
            }
        }
    
        func removePayment(with paymentData: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
            let url = APIEnvironment.current + "/front/product/payment"
            let jsonData = try? JSONSerialization.data(withJSONObject: paymentData, options: [])
            APIService.shared.fetchData(from: url, parameters: jsonData, method: .delete) { data in
                completion(true, nil)
            } failure: { error in
                completion(false, error)
            }
        }
}
