import Foundation
import CoreData

@objc(Session)
class Session: NSManagedObject {
    
    static func get(context: NSManagedObjectContext = dataStack.mainContext) -> Session? {
        let fetchRequest: NSFetchRequest<Session> = Session.fetchRequest()
        
        return try? context.fetch(fetchRequest).first
    }
    
    static func create(context: NSManagedObjectContext = dataStack.mainContext) -> Session {
        let backgroundContext = dataStack.newBackgroundContext()
        var session: Session!
        backgroundContext.performAndWait {
            session = Session(context: backgroundContext)
            do {
                try backgroundContext.save()
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        
        return session
    }
    
}
