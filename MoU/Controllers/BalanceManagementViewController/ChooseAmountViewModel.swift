import Foundation
import RxSwift
import RxCocoa

class ChooseAmountViewModel: BaseViewModel {
    
    private let amountSubject = BehaviorRelay<Float>(value: 0)
    private let amountInTextPresentationSubject = BehaviorRelay<String>(value: "0")
    private let liqpayUrlLoadedSubject = PublishRelay<URL?>()
    
    private var requestsDisposeBag = DisposeBag()
    
    func transform(input: Input) -> Output {
        input.rechargeTriggered
            .bind(onNext: getUrlForRecharging)
            .disposed(by: disposeBag)
        
        input.amountChanged
            .bind(onNext: editAmount(character:))
            .disposed(by: disposeBag)
        
        return Output(
            amount: amountInTextPresentationSubject
                .map { "\($0) ₴" }
                .asDriver(onErrorJustReturn: "0 ₴"),
            liqpayUrlLoaded: liqpayUrlLoadedSubject
                .asDriver(onErrorJustReturn: nil),
            loadingBarIndicatorVisible: loadingSubject
                .asDriver(),
            rechargeButtonEnabled: Driver.combineLatest(loadingSubject.asDriver(), amountSubject.asDriver()) { isLoading, amount in !isLoading && amount >= 10 }
        )
    }
    
}

// MARK: - INPUTS/OUTPUTS
extension ChooseAmountViewModel {
    struct Input {
        let amountChanged: Observable<String>
        let rechargeTriggered: ControlEvent<Void>
    }
    
    struct Output {
        let amount: Driver<String>
        let liqpayUrlLoaded: Driver<URL?>
        let loadingBarIndicatorVisible: Driver<Bool>
        let rechargeButtonEnabled: Driver<Bool>
    }
    
    struct Segue {
        static let liqpayWebView = "liqpayWebViewSegue"
    }
}

// MARK: - HELPER FUNCTIONS
extension ChooseAmountViewModel {
    private func getUrlForRecharging() {
        loadingSubject.accept(true)
        let amount = amountSubject.value
        
        App.shared.api.payment.rechargeBalance(amount: amount)
            .asSingle()
            .subscribeOn(concurrentQueue)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] in
                    self?.liqpayUrlLoadedSubject.accept($0)
                    self?.loadingSubject.accept(false)
                },
                onError: { [weak self] in
                    self?.errorSubject.accept($0)
                    self?.loadingSubject.accept(false)
                }
            )
            .disposed(by: requestsDisposeBag)
    }
    
    private func editAmount(character: String) {
        guard character.count <= 1 else { return }
        let amountText = amountInTextPresentationSubject.value
        var newAmountText = amountText
        
        if character.count == 1 {
            if Int(character) == nil { // It is not number - it's separator ("," or ".")
                if !amountText.contains(",") {
                    newAmountText.append(",")
                }
            } else {
                if amountText == "0" {
                    newAmountText = character
                } else if !amountText.contains(",") || amountText[amountText.index(after: amountText.firstIndex(of: ",")!)...].count <= 1 {
                    newAmountText.append(character)
                }
            }
        } else { // character.count == 0
            newAmountText.removeLast()
            if newAmountText.count == 0 {
                newAmountText = "0"
            }
        }
        
        let newAmount = Float(newAmountText.split(separator: ",").joined(separator: "."))!
        amountSubject.accept(newAmount)
        amountInTextPresentationSubject.accept(newAmountText)
    }
    
    private func cancelRequests() {
        requestsDisposeBag = DisposeBag()
    }
}
