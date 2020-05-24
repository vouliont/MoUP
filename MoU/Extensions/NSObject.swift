import Foundation

extension NSObject {
    
    var appDelegate: AppDelegate {
        return App.shared.appDelegate
    }
    
    var sceneDelegate: SceneDelegate {
        return App.shared.sceneDelegate
    }
    
    var dataStack: DataStack {
        return App.shared.dataStack
    }
    
}
