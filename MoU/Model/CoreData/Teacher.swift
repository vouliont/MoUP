import Foundation
import CoreData

@objc(Teacher)
public class Teacher: User {
    
    override var role: User.Role? {
        return .teacher
    }

    override class func parse(json: [String : Any], context: NSManagedObjectContext? = nil) -> Teacher? {
        guard let cathedraId = json["cathedraId"] as? Int64
            else { return nil }
        
        let teacher = Teacher(entity: NSEntityDescription.entity(forEntityName: "Teacher", in: context ?? dataStack.mainContext)!, insertInto: context)
        teacher.cathedraId = cathedraId
        
        if let additionalInfo = json["additionalInfo"] as? String {
            teacher.additionalInfo = additionalInfo
        }
        
        return teacher
    }
    
    override class func get() -> Teacher? {
        return super.get() as? Teacher
    }
    
}
