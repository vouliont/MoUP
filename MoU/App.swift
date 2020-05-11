import Foundation

class App {
    static var shared: App!
    
    let dataStack = DataStack()
    weak var appDelegate: AppDelegate!
    
    var api: Api!
    var session: Session?
    
    private init() {}
    
    static func initialize(delegate: AppDelegate) {
        guard shared == nil else { return }
        shared = App()
        shared.appDelegate = delegate
        
        shared.api = Api()
        shared.session = Session.get() ?? Session.create()
    }
    
    func tokenDidUpdate() {
        api.reset()
    }
    
}
