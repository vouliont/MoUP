import UIKit

extension UINavigationBar {
    
    override func addBlurEffect(withStatusBar: Bool = false) {
        self.setBackgroundImage(UIImage(), for: .default)
        
        super.addBlurEffect(withStatusBar: withStatusBar)
    }
    
//    func addBlurEffect() {
//        guard let statusBarHeight = sceneDelegate.window?
//            .windowScene?.statusBarManager?
//            .statusBarFrame.height
//            else { return }
//
//        self.setBackgroundImage(UIImage(), for: .default)
//
//        let blurredView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
//        blurredView.isUserInteractionEnabled = false
//        blurredView.frame = self.bounds
//            .insetBy(dx: 0, dy: -statusBarHeight / 2)
//            .offsetBy(dx: 0, dy: -statusBarHeight / 2)
//
//        self.addSubview(blurredView)
//
//        blurredView.layer.zPosition = -1
//    }
    
}
