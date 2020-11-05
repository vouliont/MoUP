import Foundation

class PaymentApi: BaseApi {
    
    func rechargeBalance(amount: Float) -> Requester<URL> {
        let params: [String: Any] = [
            "amount": amount
        ]
        
        return Requester(fullUrl("/payment/recharge-balance"), method: .post, params: params, headers: defaultHeaders) { response in
            guard let json = response.json as? [String: Any],
                let liqpayJson = json["liqpay"] as? [String: Any],
                let urlString = liqpayJson["url"] as? String,
                let url = URL(string: urlString)
                else { return (nil, self.errorForCode(response.code, of: RequestList.rechargeBalance)) }
            
            return (url, nil)
        }
    }
    
    func loadBalanceHistory(page: Int = 1) -> Requester<([Payment], pagination: Pagination)> {
        let params: [String: Any] = [
            "page": page
        ]
        
        return Requester(fullUrl("/balance-history"), method: .get, params: params, headers: defaultHeaders) { response in
            guard let json = response.json as? [String: Any],
                let historyBalanceJson = json["changes"] as? [[String: Any]]
                else {
                return (nil, self.errorForCode(response.code, of: RequestList.rechargeBalance))
            }
            
            let currentPage = (json["page"] as? Int) ?? 1
            let totalPages = (json["totalPages"] as? Int) ?? 1
            
            var paymentList = [Payment]()
            for paymentJson in historyBalanceJson {
                guard let payment = Payment.parse(json: paymentJson) else {
                    return (nil, self.errorForCode(response.code, of: RequestList.rechargeBalance))
                }
                paymentList.append(payment)
            }
            
            let pagination = Pagination(currentPage: currentPage, totalPages: totalPages)
            return ((paymentList, pagination: pagination), nil)
        }
    }
    
//    func payTuition(amount: Float) -> Requester<Void> {
//        
//    }
    
}

extension PaymentApi {
    enum RequestList: String, Request {
        case rechargeBalance
        
        var name: String {
            return self.rawValue
        }
    }
}
