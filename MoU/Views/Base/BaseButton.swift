import UIKit

@IBDesignable
class BaseButton: UIButton {
    
    @IBInspectable var borderColor: UIColor? {
        didSet {
            self.layer.borderColor = borderColor?.cgColor
        }
    }
    
    @IBInspectable var borderColorDisabled: UIColor?
    
    @IBInspectable var backgroundColorDefault: UIColor?
    @IBInspectable var backgroundColorDisabled: UIColor?
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set(radius) {
            self.layer.cornerRadius = radius
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return self.layer.borderWidth
        }
        set(width) {
            self.layer.borderWidth = width
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            self.layer.borderColor = isEnabled ? borderColor?.cgColor : borderColorDisabled?.cgColor
            self.layer.backgroundColor = isEnabled ? backgroundColorDefault?.cgColor : backgroundColorDisabled?.cgColor
        }
    }
    
}
