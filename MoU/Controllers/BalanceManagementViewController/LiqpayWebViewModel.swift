import Foundation
import RxSwift
import RxCocoa

class LiqpayWebViewModel: BaseViewModel {
    
    private let urlSubject: BehaviorRelay<URL>
    
    init(url: URL) {
        urlSubject = BehaviorRelay(value: url)
        
        super.init()
    }
    
    func transform(input: Input) -> Output {
        return Output(
            url: urlSubject.asDriver()
        )
    }
    
}

extension LiqpayWebViewModel {
    struct Input {
        
    }
    
    struct Output {
        let url: Driver<URL>
    }
}
