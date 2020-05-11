import Foundation
import CoreData

class DataStack {
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MoU")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    var mainContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = mainContext
        return backgroundContext
    }
    
    func performInNewBackgroundContext(_ callback: @escaping (NSManagedObjectContext) -> Void) {
        let backgroundContext = newBackgroundContext()
        backgroundContext.perform {
            callback(backgroundContext)
        }
    }
    
}
