import Foundation
import RxSwift
import RxRelay
import RxCocoa

class HomeViewModel: BaseViewModel {
    
    private let userNameSubject = BehaviorRelay<String>(value: "")
    private let emailSubject = BehaviorRelay<String>(value: "")
    private let userPhotoSubject = BehaviorRelay<Data?>(value: nil)
    private let managementLinksSubject = BehaviorRelay<[HomeCellData]>(value: [])
    
    override init() {
        super.init()
        
        let session = Session.get()!
        let userName = "\(session.user!.firstName!) \(session.user!.lastName!)"
        userNameSubject.accept(userName)
        emailSubject.accept(session.user!.email!)
        userPhotoSubject.accept(session.user!.photo)
        setupManagement(for: session.user!.role!)
    }
    
    func transform(input: Input) -> Output {
        input.logOutButtonTriggered
            .bind(onNext: performLogOut)
            .disposed(by: disposeBag)
        
        return Output(
            userName: userNameSubject.asDriver(),
            email: emailSubject.asDriver(),
            userPhoto: userPhotoSubject.asDriver(),
            managementLinks: managementLinksSubject.asDriver(),
            needPerformSegue: input.cellSelected
                .map({ indexPath in
                    let managementLinks = self.managementLinksSubject.value
                    return managementLinks[indexPath.row].segueValue
                }).asDriver(onErrorRecover: { error in
                    self.errorSubject.accept(error)
                    return Driver.empty()
                })
        )
    }
    
}

// MARK: - INPUTS/OUTPUTS
extension HomeViewModel {
    struct Input {
        let cellSelected: ControlEvent<IndexPath>
        let logOutButtonTriggered: ControlEvent<Void>
    }
    
    struct Output {
        let userName: Driver<String>
        let email: Driver<String>
        let userPhoto: Driver<Data?>
        let managementLinks: Driver<[HomeCellData]>
        let needPerformSegue: Driver<String>
    }
}

// MARK: - HELPER FUNCTIONS
extension HomeViewModel {
    private func setupManagement(for role: User.Role) {
        switch role {
        case .admin:
            managementLinksSubject.accept([
                HomeCellData(title: "FACULTIES", segue: .faculties)
            ])
        case .student:
            break
        default:
            break
        }
    }
    
    private func performLogOut() {
        App.shared.api.session.logOut()
            .asSingle()
            .flatMapCompletable(logOutUser)
            .do(onCompleted: App.shared.tokenDidUpdate)
            .subscribeOn(concurrentQueue)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onCompleted: {
                    self.sceneDelegate.loadController()
                },
                onError: { self.errorSubject.accept($0) }
            )
            .disposed(by: disposeBag)
    }
    
    private func logOutUser() -> Completable {
        return Completable.create { completable in
            self.dataStack.performInNewBackgroundContext { context in
                let session = Session.get(context: context)
                session?.token = nil
                context.delete(session!.user!)
                
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
}
