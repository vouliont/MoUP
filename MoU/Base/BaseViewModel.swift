import Foundation
import RxSwift
import RxRelay
import RxCocoa

class BaseViewModel: NSObject {
    
    let concurrentQueue = ConcurrentDispatchQueueScheduler(qos: .background)
    
    let loadingSubject = BehaviorRelay<Bool>(value: false)
    let errorSubject = PublishRelay<Error>()
    
    lazy var loading: Driver<Bool> = {
        return loadingSubject.asDriver()
    }()
    
    let disposeBag = DisposeBag()
    
}
