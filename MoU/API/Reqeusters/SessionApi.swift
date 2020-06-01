import Foundation
import CoreData

class SessionApi: BaseApi {
    
    override var requestErrors: [String : [Int : String]] {
        return [
            RequestList.logIn.name: [
                400: "SESSION_WAS_NOT_INITIATED",
                404: "USER_NOT_FOUND"
            ]
        ]
    }
    
    func logIn(login: String? = nil, email: String? = nil, password: String) -> Requester<String> {
        var params: [String: Any] = [
            "password": password
        ]
        if let login = login {
            params["loginName"] = login
        } else if let email = email {
            params["email"] = email
        }
        
        return Requester(fullUrl("/user/session"), method: .post, params: params, headers: defaultHeaders) { response in
            if let json = response.json as? [String: Any],
                let token = json["token"] as? String {
                return (token, nil)
            }
            
            return (nil, self.errorForCode(response.code, of: RequestList.logIn))
        }
    }
    
    func logOut() -> Requester<Void> {
        return Requester(fullUrl("/user/session"), method: .delete, headers: defaultHeaders) { response in
            if response.code == 204 {
                return ((), nil)
            }
            return (nil, self.errorForCode(response.code, of: RequestList.logOut))
        }
    }
    
    func getUserData(context: NSManagedObjectContext? = nil) -> Requester<User> {
        return Requester(fullUrl("/user/data"), method: .get, headers: defaultHeaders) { response in
            if let json = response.json as? [String: Any],
                let user = User.parse(json: json, context: context) {
                return (user, nil)
            }
            
            return (nil, self.errorForCode(response.code, of: RequestList.getUserData))
        }
    }
    
}

extension SessionApi {
    enum RequestList: String, Request {
        case logIn
        case logOut
        case getUserData
        
        var name: String {
            return self.rawValue
        }
    }
}
