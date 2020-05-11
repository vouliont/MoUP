import Foundation
import CoreData

class SessionApi: BaseApi {
    
    override var errorCodes: [Int : String] {
        return super.errorCodes.merging([
            400: "SESSION_WAS_NOT_INITIATED",
            404: "USER_NOT_FOUND"
        ]) { source1, source2 in source2 }
    }
    
    func logIn(login: String, password: String) -> Requester<String> {
        let params: [String: Any] = [
            "loginName": login,
            "password": password
        ]
        
        return Requester(fullUrl("/user/session"), method: .post, params: params, headers: defaultHeaders) { response in
            if let token = response.json["token"] as? String {
                return (token, nil)
            }
            
            return (nil, self.errorForCode(response.code))
        }
    }
    
    func getUserData(context: NSManagedObjectContext? = nil) -> Requester<User> {
        return Requester(fullUrl("/user/data"), method: .get, headers: defaultHeaders) { response in
            if let user = User.parse(json: response.json, context: context) {
                return (user, nil)
            }
            
            return (nil, self.errorForCode(response.code))
        }
    }
    
}
