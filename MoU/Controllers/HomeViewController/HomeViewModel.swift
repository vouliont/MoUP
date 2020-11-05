import Foundation
import RxSwift
import RxRelay
import RxCocoa

class HomeViewModel: BaseViewModel {
    
    private let userSubject: BehaviorRelay<User>
    private let managementLinksSubject = BehaviorRelay<[HomeCellData]>(value: [])
    
    override init() {
        let user = User.get()!
        userSubject = BehaviorRelay(value: user)
        
        super.init()
        
        setupManagement(for: user.role!)
        
        NotificationCenter.default.addObserver(self, selector: #selector(userUpdated), name: .userDidUpdate, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func transform(input: Input) -> Output {
        input.logOutButtonTriggered
            .bind(onNext: { [unowned self] in
                self.performLogOut()
            })
            .disposed(by: disposeBag)
        
        input.viewDidAppear
            .map { _ in () }
            .bind(onNext: App.shared.updateUser)
            .disposed(by: disposeBag)
        
        return Output(
            userName: userSubject
                .map { "\($0.firstName!) \($0.lastName!)" }
                .asDriver(onErrorJustReturn: ""),
            email: userSubject
                .map { $0.email! }
                .asDriver(onErrorJustReturn: ""),
            userPhoto: userSubject
                .map { $0.photo }
                .asDriver(onErrorJustReturn: nil),
            managementLinks: managementLinksSubject.asDriver(),
            needPerformSegue: input.cellSelected
                .map({ [unowned self] indexPath in
                    let managementLinks = self.managementLinksSubject.value
                    return managementLinks[indexPath.row].segueValue
                }).asDriver(onErrorRecover: { [unowned self] error in
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
        let viewDidAppear: ControlEvent<Bool>
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
                HomeCellData(title: "FACULTIES", segue: .faculties),
                HomeCellData(title: "LESSONS", segue: .lessons)
            ])
        case .student:
            managementLinksSubject.accept([
                HomeCellData(title: "BALANCE_MANAGEMENT", segue: .balanceManagement)
            ])
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
                onCompleted: { [weak self] in
                    self?.sceneDelegate.loadController()
                },
                onError: { [weak self] in self?.errorSubject.accept($0) }
            )
            .disposed(by: disposeBag)
    }
    
    private func logOutUser() -> Completable {
        return Completable.create { [unowned self] completable in
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
    
    @objc private func userUpdated() {
        guard let user = User.get() else { return }
        userSubject.accept(user)
    }
}
