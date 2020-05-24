import UIKit

extension UIResponder {
    
    var windowSafeAreaInsets: UIEdgeInsets? {
        let window = sceneDelegate.window
        return window?.safeAreaInsets
    }
    
}
