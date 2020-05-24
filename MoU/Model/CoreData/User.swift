import Foundation
import CoreData

@objc(User)
public class User: NSManagedObject {
    
    enum Role: String {
        case admin = "admin"
        case teacher = "teacher"
        case student = "student"
    }
    
    var role: Role? {
        guard let roleName = roleName else { return nil }
        return Role(rawValue: roleName)
    }
    
    static func parse(json: [String: Any], context: NSManagedObjectContext? = nil) -> User? {
        guard let id = json["id"] as? Int64,
            let firstName = json["firstName"] as? String,
            let lastName = json["lastName"] as? String,
            let middleName = json["middleName"] as? String,
            let loginName = json["loginName"] as? String,
            let email = json["email"] as? String,
            let roleName = json["roleName"] as? String,
            let birthday = (json["birthday"] as? String)?.toDateFromISO8601(),
            let status = json["status"] as? String,
            let lastActiveTime = (json["lastActiveTime"] as? String)?.toDateFromISO8601(),
            let createdAt = (json["createdAt"] as? String)?.toDateFromISO8601(),
            let updatedAt = (json["updatedAt"] as? String)?.toDateFromISO8601()
            else { return nil }
        
        let user = User(entity: NSEntityDescription.entity(forEntityName: "User", in: context ?? dataStack.mainContext)!, insertInto: context)
        user.id = id
        user.firstName = firstName
        user.lastName = lastName
        user.middleName = middleName
        user.loginName = loginName
        user.email = email
        user.roleName = roleName
        user.birthday = birthday
        user.status = status
        user.lastActiveTime = lastActiveTime
        user.createdAt = createdAt
        user.updatedAt = updatedAt
        return user
    }
    
}
