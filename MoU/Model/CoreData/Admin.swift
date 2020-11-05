import Foundation
import CoreData

@objc(Admin)
public class Admin: User {
    
    override var role: User.Role? {
        return .admin
    }
    
    override class func parse(json: [String: Any], context: NSManagedObjectContext? = nil) -> Admin? {
        return Admin(entity: NSEntityDescription.entity(forEntityName: "Admin", in: context ?? dataStack.mainContext)!, insertInto: context)
    }
    
    override class func get() -> Admin? {
        return super.get() as? Admin
    }
    
}
