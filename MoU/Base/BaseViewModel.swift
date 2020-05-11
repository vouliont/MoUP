import Foundation
import RxSwift
import RxRelay

class BaseViewModel: NSObject {
    
    let loadingSubject = BehaviorRelay<Bool>(value: false)
    let errorSubject = PublishRelay<Error>()
    
    let disposeBag = DisposeBag()
    
}
