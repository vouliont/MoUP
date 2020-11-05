import Foundation
import CoreData

/**
* `User`
* - id
* - firstName
* - lastName
* - middleName
* - loginName
* - email
* - roleName
* - birthday
* - photo/path?
*
* `Student`
* - id
* - balance
* - groupId
* - learnFormId
*
* `Teacher`
* - id
* - additionalInfo
* - cathedraId
*/
@objc(User)
public class User: NSManagedObject {
    
    enum Role: String {
        case admin = "admin"
        case teacher = "teacher"
        case student = "student"
    }
    
    var role: Role? {
        return nil
    }
    
    var lastNameWithInitials: String {
        return "\(lastName!) \(firstName!.first!).\(middleName!.first!)."
    }
    
    var fullName: String {
        return "\(lastName!) \(firstName!) \(middleName!)"
    }
    
    class func parse(json: [String: Any], context: NSManagedObjectContext? = nil) -> User? {
        guard let roleName = json["roleName"] as? String,
            let role = Role(rawValue: roleName),
            let id = json["id"] as? Int64,
            let firstName = json["firstName"] as? String,
            let lastName = json["lastName"] as? String,
            let middleName = json["middleName"] as? String,
            let loginName = json["loginName"] as? String,
            let email = json["email"] as? String,
            let birthday = (json["birthday"] as? String)?.toDateFromISO8601()
            else { return nil }
        
        let user: User?
        
        switch role {
        case .admin:
            user = Admin.parse(json: [:], context: context)
        case .student:
            guard let studentJson = json["student"] as? [String: Any] else { return nil }
            user = Student.parse(json: studentJson, context: context)
        case .teacher:
            guard let teacherJson = json["teacher"] as? [String: Any] else { return nil }
            user = Teacher.parse(json: teacherJson, context: context)
        }
        
        user?.id = id
        user?.firstName = firstName
        user?.lastName = lastName
        user?.middleName = middleName
        user?.loginName = loginName
        user?.email = email
        user?.birthday = birthday
        
        if let photoJson = json["photo"] as? [String: Any],
            let photoPath = photoJson["path"] as? String {
            let fullPhotoPath = "\(App.shared.api.baseUrl)/\(photoPath)"
            user?.photoPath = fullPhotoPath
        }
        
        return user
    }
    
    class func get() -> User? {
        return Session.get()?.user
    }
    
}

extension User {
    enum UpdatedPart {
        case payments
        case entirely
    }
}
