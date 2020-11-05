import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        App.shared.sceneDelegate = self
        loadController()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        
    }

    func sceneWillResignActive(_ scene: UIScene) {
        appDelegate.saveContext()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        appDelegate.saveContext()
    }

}

extension SceneDelegate {
    private func isLoggedIn() -> Bool {
        return App.shared.session.token != nil
    }
    
    func loadController() {
        isLoggedIn() ? loadMainViewController() : loadLoginViewController()
    }
    
    func loadLoadingController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loadingViewController = storyboard.instantiateInitialViewController()!
        window?.rootViewController = loadingViewController
    }
    
    private func loadLoginViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = storyboard.instantiateViewController(withIdentifier: "loginViewController")
        window?.rootViewController = loginViewController
    }
    
    private func loadMainViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let homeViewController = storyboard.instantiateViewController(withIdentifier: "homeViewController")
        window?.rootViewController = homeViewController
    }
}

