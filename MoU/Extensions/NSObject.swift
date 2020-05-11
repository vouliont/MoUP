import UIKit

extension NSObject {
    
    var appDelegate: AppDelegate {
        return App.shared.appDelegate
    }
    
    var dataStack: DataStack {
        return App.shared.dataStack
    }
    
}
