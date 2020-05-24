import UIKit

extension UIView {
    
    func hideWithConstraints() -> [NSLayoutConstraint] {
        self.isHidden = true
        
        var constraints = [NSLayoutConstraint]()
        constraints.append(contentsOf: self.constraints)
        constraints.append(contentsOf: self.superview?.constraints
            .filter {
                ($0.firstItem as? UIView) === self || ($0.secondItem as? UIView) === self
            } ?? []
        )
        
        NSLayoutConstraint.deactivate(constraints)
        
        return constraints
    }
    
    func showWithConstraints(_ constraints: [NSLayoutConstraint]) {
        self.isHidden = false
        
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc func addBlurEffect(withStatusBar: Bool = false) {
        guard !hasBlurEffect else { return }
        
        let statusBarHeight = withStatusBar ?
            (sceneDelegate.window?
                .windowScene?.statusBarManager?
                .statusBarFrame.height ?? 0)
            : 0
        
        let blurredView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        blurredView.tag = 28121998
        blurredView.isUserInteractionEnabled = false
        blurredView.frame = self.bounds
            .insetBy(dx: 0, dy: -statusBarHeight / 2)
            .offsetBy(dx: 0, dy: -statusBarHeight / 2)
        
        self.addSubview(blurredView)
        
        blurredView.layer.zPosition = -1
    }
    
    private var hasBlurEffect: Bool {
        return self.subviews.contains(where: { $0.tag == 28121998 })
    }
    
}
