import Foundation

class Api: NSObject {
    
    let baseUrl = "https://univ-system.herokuapp.com"
    var defaultHeaders = [String: String]()
    
    let session: SessionApi
    let general: GeneralApi
    let payment: PaymentApi
    
    override init() {
        session = SessionApi(baseUrl: baseUrl)
        general = GeneralApi(baseUrl: baseUrl)
        payment = PaymentApi(baseUrl: baseUrl)
        
        super.init()
        
        reset()
    }

    func reset() {
        if let token = App.shared.session.token {
            defaultHeaders["X-Auth-Token"] = token
        } else {
            defaultHeaders.removeValue(forKey: "X-Auth-Token")
        }
        
        session.defaultHeaders = defaultHeaders
        general.defaultHeaders = defaultHeaders
        payment.defaultHeaders = defaultHeaders
    }
    
}
