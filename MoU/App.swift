import Foundation

class App {
    static var shared: App!
    
    let dataStack = DataStack()
    weak var appDelegate: AppDelegate!
    weak var sceneDelegate: SceneDelegate!
    
    var api: Api!
    var session: Session {
        return Session.get() ?? Session.create()
    }
    
    private init() {}
    
    static func initialize(delegate: AppDelegate) {
        guard shared == nil else { return }
        shared = App()
        shared.appDelegate = delegate
        
        shared.api = Api()
    }
    
    func tokenDidUpdate() {
        api.reset()
    }
    
    func logUserOut() {
        DispatchQueue.main.async {
            self.sceneDelegate.loadLoadingController()
        }
        
        dataStack.performInNewBackgroundContext { context in
            let session = Session.get(context: context)!
            
            context.delete(session.user!)
            session.token = nil
            
            do {
                try context.save()
                DispatchQueue.main.async {
                    self.sceneDelegate.loadController()
                }
            } catch {
                print(error)
            }
        }
        
    }
    
}
