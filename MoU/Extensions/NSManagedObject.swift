import Foundation
import CoreData

extension NSManagedObject {
    
    static var dataStack: DataStack {
        return App.shared.dataStack
    }
    
}
