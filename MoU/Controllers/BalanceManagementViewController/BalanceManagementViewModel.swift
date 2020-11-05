import Foundation
import RxSwift
import RxCocoa

class BalanceManagementViewModel: BaseViewModel {
    
    let loadMorePaymentsSubject = PublishSubject<Void>()
    
    private let currentPageSubject = BehaviorRelay<Int>(value: 0)
    private let totalPagesSubject = BehaviorRelay<Int>(value: 1)
    private let studentSubject: BehaviorRelay<Student>
    private let historyBalanceSubject = BehaviorRelay<[PaymentCellData]>(value: [
        PaymentCellData(item: nil, cellType: .loadingCell)
    ])
    private let loadingHistorySubject = BehaviorRelay<Bool>(value: false)
    
    private var requestsDisposeBag = DisposeBag()
    
    override init() {
        studentSubject = BehaviorRelay(value: Student.get()!)
        
        super.init()
        
        loadMorePaymentsSubject
            .filter { [unowned self] in !self.loadingHistorySubject.value }
            .map { [unowned self] in self.currentPageSubject.value + 1 }
            .bind(to: currentPageSubject)
            .disposed(by: disposeBag)

        loadMorePaymentsSubject
            .map { true }
            .bind(to: loadingHistorySubject)
            .disposed(by: disposeBag)

        historyBalanceSubject
            .skip(1)
            .map { _ in false }
            .bind(to: loadingHistorySubject)
            .disposed(by: disposeBag)

        currentPageSubject
            .filter { $0 != 0 }
            .bind(onNext: { [unowned self] in
                self.loadHistory(for: $0)
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.addObserver(self, selector: #selector(studentUpdated(_:)), name: .userDidUpdate, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func transform(input: Input) -> Output {
        input.viewDidDisappear
            .map { _ in () }
            .bind(onNext: { [unowned self] in
                self.cancelRequests()
            })
            .disposed(by: disposeBag)
        
        return Output(
            balance: studentSubject
                .map { $0.balance }
                .map { Helpers.amountWithCurrency($0) }
                .asDriver(onErrorJustReturn: ""),
            historyBalance: historyBalanceSubject
                .asDriver()
        )
    }
    
}

// MARK: - INPUTS/OUTPUTS
extension BalanceManagementViewModel {
    struct Input {
        let viewDidDisappear: ControlEvent<Bool>
    }
    
    struct Output {
        let balance: Driver<String>
        let historyBalance: Driver<[PaymentCellData]>
    }
    
    struct Segue {
        static let rechargeBalance = "rechargeBalanceSegue"
    }
}

// MARK: - HELPER FUNCTIONS
extension BalanceManagementViewModel {
    @objc private func studentUpdated(_ notification: Notification) {
        guard let object = notification.object as? User.UpdatedPart, object == .payments else { return }
        guard let student = Student.get() else { return }
        studentSubject.accept(student)
        currentPageSubject.accept(0)
        totalPagesSubject.accept(1)
        historyBalanceSubject.accept([
            PaymentCellData(item: nil, cellType: .loadingCell)
        ])
    }
    
    private func loadHistory(for page: Int) {
        App.shared.api.payment.loadBalanceHistory(page: page)
            .asSingle()
            .subscribeOn(concurrentQueue)
            .observeOn(concurrentQueue)
            .subscribe(
                onSuccess: { [weak self] result in
                    guard let strongSelf = self else { return }
                    let (payments, pagination) = result
                    strongSelf.totalPagesSubject.accept(pagination.totalPages)
                    
                    var paymentCellsData = strongSelf.historyBalanceSubject.value
                    if paymentCellsData.last?.cellType == CellType.loadingCell {
                        paymentCellsData.removeLast()
                    }
                    for payment in payments {
                        if (paymentCellsData.contains { $0.item === payment }) {
                            break
                        }
                        let paymentCellData = PaymentCellData(item: payment, cellType: .paymentCell)
                        paymentCellsData.append(paymentCellData)
                    }
                    if pagination.currentPage < pagination.totalPages {
                        let paymentCellData = PaymentCellData(item: nil, cellType: .loadingCell)
                        paymentCellsData.append(paymentCellData)
                    }
                    
                    strongSelf.historyBalanceSubject.accept(paymentCellsData)
                },
                onError: { [weak self] in self?.errorSubject.accept($0) }
            )
            .disposed(by: requestsDisposeBag)
    }
    
    private func cancelRequests() {
        requestsDisposeBag = DisposeBag()
    }
}
