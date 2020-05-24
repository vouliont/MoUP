import UIKit

class RestrictTextField: UITextField {
    enum ActionType: String {
        case copy = "copy:"
        case paste = "paste:"
        case cut = "cut:"
    }
    
    var restrictedActions = [ActionType]()
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if restrictedActions
            .map({ Selector($0.rawValue) })
            .contains(where: { $0 == action })
        {
            return false
        }
        
        return super.canPerformAction(action, withSender: sender)
    }
}
