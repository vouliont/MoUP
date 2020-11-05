import Foundation
import CoreData

@objc(Student)
public class Student: User {
    
    override var role: User.Role? {
        return .student
    }
    
    override class func parse(json: [String: Any], context: NSManagedObjectContext? = nil) -> Student? {
        guard let groupId = json["groupId"] as? Int64,
            let learnFormId = json["learnFormId"] as? Int64
            else { return nil }
        
        let student = Student(entity: NSEntityDescription.entity(forEntityName: "Student", in: context ?? dataStack.mainContext)!, insertInto: context)
        
        student.balance = (json["balance"] as? Float) ?? 0
        student.groupId = groupId
        student.learnFormId = learnFormId
        
        if let blocked = json["blocked"] as? Bool {
            student.blocked = blocked
        }
        if let needPaySum = json["needPaySum"] as? Float {
            student.needPaySum = needPaySum
        }
        
        return student
    }
    
    override class func get() -> Student? {
        return super.get() as? Student
    }
    
}
