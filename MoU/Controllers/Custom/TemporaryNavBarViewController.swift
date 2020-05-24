import UIKit

/**
 * This view controller is for showing navigation bar temporary
 * during pushing the view controller into a navigation view controller.
 */
class TemporaryNavBarViewController: BaseViewController {
    
    var navigationBar: UINavigationBar!
    var navigationBarHeight: CGFloat {
        return navigationBar.isHidden ? 0 : navigationBar.bounds.height
    }
    
    private var indexInNavigationStack: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addNavigationBar()
        indexInNavigationStack = navigationController?.viewControllers.firstIndex(of: self) ?? 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationBar.isHidden = true
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (navigationController?.viewControllers.count ?? 0) - 1 < indexInNavigationStack {
            navigationBar.isHidden = false
        }
    }
    
    private func addNavigationBar() {
        let statusBarHeight = sceneDelegate.window?
            .windowScene?.statusBarManager?
            .statusBarFrame.height ?? 0
        let navigationBarHeight = navigationController?.navigationBar.bounds.height ?? 44
        
        let navigationBar = UINavigationBar(frame: CGRect(x: 0, y: statusBarHeight, width: UIScreen.main.bounds.width, height: navigationBarHeight))
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(navigationBar)
        NSLayoutConstraint.activate([
            navigationBar.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            navigationBar.topAnchor.constraint(equalTo: self.view.topAnchor, constant: statusBarHeight),
            navigationBar.heightAnchor.constraint(equalToConstant: navigationBarHeight)
        ])
        
        navigationBar.pushItem(UINavigationItem(), animated: false)
        navigationBar.pushItem(UINavigationItem(title: navigationItem.title ?? ""), animated: false)
        navigationBar.addBlurEffect(withStatusBar: true)
        
        self.navigationBar = navigationBar
    }
    
}
