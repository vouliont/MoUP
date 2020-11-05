import Foundation
import CoreData
import RxSwift

class App {
    static var shared: App!
    
    let dataStack = DataStack()
    weak var appDelegate: AppDelegate!
    weak var sceneDelegate: SceneDelegate!
    
    var api: Api!
    var session: Session {
        return Session.get() ?? Session.create()
    }
    
    private var disposeBag = DisposeBag()
    
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
    
    func updateUser(with object: Any? = nil) {
        DispatchQueue.global(qos: .background).async {
            self.disposeBag = DisposeBag()
            
            let backgroundContext = self.dataStack.newBackgroundContext()
            self.api.session.getUserData(context: backgroundContext)
                .asSingle()
                .flatMapCompletable({
                    self.persistUser($0, context: backgroundContext)
                })
                .subscribe(onCompleted: {
                    NotificationCenter.default.post(Notification(name: .userDidUpdate, object: object))
                })
                .disposed(by: self.disposeBag)
        }
    }
    
    func persistUser(_ user: User, context: NSManagedObjectContext) -> Completable {
        return Completable.create { completable in
            context.perform {
                if let photoPath = user.photoPath, let url = URL(string: photoPath) {
                    user.photo = self.loadUserPhoto(from: url)
                }
                
                context.insert(user)
                
                let session = Session.get(context: context)!
                session.user = user
                
                do {
                    try context.save()
                    completable(.completed)
                } catch {
                    context.rollback()
                    completable(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    private func loadUserPhoto(from url: URL) -> Data? {
        return try? Data(contentsOf: url)
    }
    
}
