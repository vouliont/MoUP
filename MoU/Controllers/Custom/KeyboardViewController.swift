import UIKit

class KeyboardViewController: BaseViewController {
    
    @IBOutlet var mainView: UIView!
    @IBOutlet var mainViewBottomPadding: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        subscribeKeyboardNotifications()
    }
    
    deinit {
        unsubscribeKeyboardNotifications()
    }
    
    private func subscribeKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func unsubscribeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillChange(notification: Notification) {
        let keyboardSizeOptional: CGRect?
        if notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification {
            keyboardSizeOptional = keyboardEndSize(from: notification)
        } else {
            keyboardSizeOptional = CGRect.zero
        }
        guard let keyboardSize = keyboardSizeOptional else {
            return
        }
        let duration = keyboardAnimationDuration(from: notification) ?? 0
        
        mainViewBottomPadding.constant = keyboardSize.height
        
        UIView.animate(withDuration: duration) {
            self.mainView.superview?.layoutIfNeeded()
        }
    }

    private func keyboardAnimationDuration(from notification: Notification) -> TimeInterval? {
        return notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
    }
    
    private func keyboardEndSize(from notification: Notification) -> CGRect? {
        return (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
    }

}
