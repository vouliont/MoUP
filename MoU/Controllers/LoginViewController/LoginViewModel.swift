import Foundation
import RxSwift
import RxCocoa
import CoreData

class LoginViewModel: BaseViewModel {
    
    private lazy var backgroundContext : NSManagedObjectContext = {
        return dataStack.newBackgroundContext()
    }()
    
    private let loginSubject = BehaviorRelay<String>(value: "")
    private let passwordSubject = BehaviorRelay<String>(value: "")
    
    private let tokenLoadedSubject = PublishRelay<Void>()
    private let userDataLoadedSubject = PublishSubject<Void>()
    
    private let requestDisposeBag = DisposeBag()
    
    override init() {
        super.init()
    }
    
    func transform(input: Input) -> Output {
        input.loginTextFieldTextChanged
            .map { $0 ?? "" }
            .bind(to: loginSubject)
            .disposed(by: disposeBag)
        input.passwordTextFieldTextChanged
            .map { $0 ?? "" }
            .bind(to: passwordSubject)
            .disposed(by: disposeBag)
        
        input.logInButtonTriggered
            .do(onNext: { self.loadingSubject.accept(true) })
            .observeOn(concurrentQueue)
            .bind(onNext: logIn)
            .disposed(by: disposeBag)
        
        tokenLoadedSubject
            .do(onNext: App.shared.tokenDidUpdate)
            .bind(onNext: getUserInfo)
            .disposed(by: disposeBag)
        
        userDataLoadedSubject
            .observeOn(MainScheduler.instance)
            .bind(onNext: sceneDelegate.loadController)
            .disposed(by: disposeBag)

        let logInButtonEnable = Observable.combineLatest(
            loginSubject.map(verifyLogin),
            passwordSubject.map(verifyPassword),
            loadingSubject
        ) { $0 && $1 && !$2 }
        
        return Output(
            logInButtonEnable: logInButtonEnable.asDriver(onErrorJustReturn: false),
            userDataLoaded: userDataLoadedSubject.asDriver(onErrorJustReturn: ()),
            errorHasOccured: errorSubject
                .map { ($0 as? ApiError)?.localizedDescription ?? ApiError.general.localizedDescription }
                .asDriver(onErrorJustReturn: ApiError.general.localizedDescription)
        )
    }
    
}

// MARK: - INPUTS/OUTPUTS
extension LoginViewModel {
    struct Input {
        let loginTextFieldTextChanged: ControlProperty<String?>
        let passwordTextFieldTextChanged: ControlProperty<String?>
        let logInButtonTriggered: ControlEvent<Void>
    }
    
    struct Output {
        let logInButtonEnable: Driver<Bool>
        let userDataLoaded: Driver<Void>
        let errorHasOccured: Driver<String>
    }
}

// MARK: - HELPER FUNCTIONS
extension LoginViewModel {
    
    private func verifyLogin(_ login: String) -> Bool {
        return login.count >= 3
    }
    
    private func verifyPassword(_ password: String) -> Bool {
        return password.count >= 6
    }
    
    private func logIn() {
        let isEmail = loginSubject.value.contains("@")
        let login: String? = isEmail ? nil : loginSubject.value
        let email: String? = isEmail ? loginSubject.value : nil
        let password = passwordSubject.value
        
        App.shared.api.session.logIn(login: login, email: email, password: password)
            .asSingle()
            .flatMapCompletable(persistToken)
            .subscribeOn(concurrentQueue)
            .subscribe(
                onCompleted: { self.tokenLoadedSubject.accept(()) },
                onError: {
                    self.errorSubject.accept($0)
                    self.loadingSubject.accept(false)
                }
            ).disposed(by: requestDisposeBag)
    }
    
    private func persistToken(_ token: String) -> Completable {
        return Completable.create { completable in
            self.appDelegate.dataStack.performInNewBackgroundContext { context in
                let session = Session.get(context: context)!
                session.token = token
                
                do {
                    try context.save()
                    completable(.completed)
                } catch {
                    completable(.error(error))
                }
            }
            return Disposables.create()
        }
    }
    
    private func getUserInfo() {
        App.shared.api.session.getUserData(context: backgroundContext)
            .asSingle()
            .flatMapCompletable(persistUser)
            .subscribeOn(concurrentQueue)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onCompleted: { self.userDataLoadedSubject.onNext(()) },
                onError: {
                    self.errorSubject.accept($0)
                    self.loadingSubject.accept(false)
                }
            ).disposed(by: requestDisposeBag)
    }
    
    private func persistUser(_ user: User) -> Completable {
        return Completable.create { completable in
            self.backgroundContext.perform {
                if let photoPath = user.photoPath, let url = URL(string: photoPath) {
                    user.photo = self.loadUserPhoto(from: url)
                }
                
                self.backgroundContext.insert(user)
                
                let session = Session.get(context: self.backgroundContext)!
                session.user = user
                
                do {
                    try self.backgroundContext.save()
                    completable(.completed)
                } catch {
                    self.backgroundContext.rollback()
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
