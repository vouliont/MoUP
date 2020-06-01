import Foundation
import RxSwift
import RxCocoa

class CathedraCreateEditViewModel: BaseViewModel {
    
    let cathedraToBeEditedSubject: BehaviorRelay<Cathedra?>
    private let facultySubject: BehaviorRelay<Faculty>
    
    private let navItemTitleSubject: BehaviorRelay<String>
    
    private let cathedraNameSubject = BehaviorRelay<String?>(value: nil)
    private let foundedDateSubject = BehaviorRelay<Date?>(value: nil)
    private let siteUrlSubject = BehaviorRelay<String?>(value: nil)
    private let additionalInfoSubject = BehaviorRelay<String?>(value: nil)
    
    private let foundedDateEditingSubject = BehaviorRelay<Bool>(value: false)
    
    let cathedraManipulatedSubject = PublishSubject<Cathedra?>()
    let cathedraDeletedSubject = PublishSubject<Bool>()
    
    private var requestDisposeBag = DisposeBag()
    
    let minimumDate = Date.fromDefaultFormattedString("01.01.1990")!
    let maximumDate = Date()
    
    init(cathedraToBeEdited: Cathedra?, on faculty: Faculty) {
        cathedraToBeEditedSubject = BehaviorRelay(value: cathedraToBeEdited)
        facultySubject = BehaviorRelay(value: faculty)
        
        navItemTitleSubject = BehaviorRelay(value: cathedraToBeEdited == nil ? "NEW_CATHEDRA_TITLE".localized : "EDIT_CATHEDRA_TITLE".localized)
        
        super.init()
        
        cathedraToBeEditedSubject
            .filter { $0 != nil }
            .map { $0!.name }
            .bind(to: cathedraNameSubject)
            .disposed(by: disposeBag)
        cathedraToBeEditedSubject
            .map { $0?.foundedDate }
            .bind(to: foundedDateSubject)
            .disposed(by: disposeBag)
        cathedraToBeEditedSubject
            .map { $0?.siteUrl }
            .bind(to: siteUrlSubject)
            .disposed(by: disposeBag)
        cathedraToBeEditedSubject
            .map { $0?.additionalInfo }
            .bind(to: additionalInfoSubject)
            .disposed(by: disposeBag)
    }
    
    func transform(input: Input) -> Output {
        input.saveTrigger
            .bind(onNext: saveCathedra)
            .disposed(by: disposeBag)
        
        input.cancelTrigger
            .bind(onNext: {
                self.cathedraManipulatedSubject.onCompleted()
            })
            .disposed(by: disposeBag)
        
        input.deleteTrigger
            .bind(onNext: deleteCathedra)
            .disposed(by: disposeBag)
        
        input.cathedraNameChanged
            .skip(1)
            .map { $0 ?? "" }
            .bind(to: cathedraNameSubject)
            .disposed(by: disposeBag)
        
        input.siteUrlChanged
            .skip(1)
            .bind(to: siteUrlSubject)
            .disposed(by: disposeBag)
        
        input.datePickerValueChanged
            .filter { _ in self.foundedDateEditingSubject.value }
            .bind(to: foundedDateSubject)
            .disposed(by: disposeBag)
        
        input.foundedDateEditingDidBegin
            .map { true }
            .bind(to: foundedDateEditingSubject)
            .disposed(by: disposeBag)
        input.foundedDateEditingDidEnd
            .map { false }
            .bind(to: foundedDateEditingSubject)
            .disposed(by: disposeBag)
        
        input.foundedDateChanged
            .skip(1)
            .map({ dateString -> Date? in
                guard let dateString = dateString,
                    let date = Date.fromDefaultFormattedString(dateString)
                    else { return nil }
                return date
            })
            .bind(to: foundedDateSubject)
            .disposed(by: disposeBag)
        
        input.additionalInfoChanged
            .skip(1)
            .bind(to: additionalInfoSubject)
            .disposed(by: disposeBag)
        
        input.viewDidDissapear
            .map { _ in () }
            .bind(onNext: cancelRequests)
            .disposed(by: disposeBag)
        
        return Output(
            navItemTitle: navItemTitleSubject.asDriver(),
            saveBarButtonItemEnabled: cathedraNameSubject
                .map { $0?.count ?? 0 >= 6 }
                .asDriver(onErrorJustReturn: false),
            cathedraName: cathedraNameSubject.asDriver(),
            foundedDate: foundedDateSubject
                .filter { $0 != nil}
                .map { $0!.toDefaultFormattedString() }
                .asDriver(onErrorJustReturn: ""),
            siteUrl: siteUrlSubject.asDriver(),
            additionalInfo: additionalInfoSubject.asDriver(),
            cathedraDidManipulate: cathedraManipulatedSubject.asDriver(onErrorJustReturn: nil),
            datePickerValue: foundedDateSubject
                .filter { _ in !self.foundedDateEditingSubject.value }
                .map { $0 ?? Date() }
                .asDriver(onErrorJustReturn: Date()),
            deleteButtonVisible: cathedraToBeEditedSubject
                .map { $0 != nil }
                .asDriver(onErrorJustReturn: false)
        )
    }
    
}

// MARK: - INPUTS/OUTPUTS
extension CathedraCreateEditViewModel {
    struct Input {
        let saveTrigger: ControlEvent<Void>
        let cancelTrigger: ControlEvent<Void>
        let deleteTrigger: ControlEvent<Void>
        let cathedraNameChanged: ControlProperty<String?>
        let foundedDateChanged: ControlProperty<String?>
        let siteUrlChanged: ControlProperty<String?>
        let additionalInfoChanged: ControlProperty<String?>
        let datePickerValueChanged: ControlProperty<Date>
        let foundedDateEditingDidBegin: ControlEvent<Void>
        let foundedDateEditingDidEnd: ControlEvent<Void>
        let viewDidDissapear: ControlEvent<Bool>
    }
    
    struct Output {
        let navItemTitle: Driver<String>
        let saveBarButtonItemEnabled: Driver<Bool>
        let cathedraName: Driver<String?>
        let foundedDate: Driver<String?>
        let siteUrl: Driver<String?>
        let additionalInfo: Driver<String?>
        let cathedraDidManipulate: Driver<Cathedra?>
        let datePickerValue: Driver<Date>
        let deleteButtonVisible: Driver<Bool>
    }
}

// MARK: - HELPER FUNCTIONS
extension CathedraCreateEditViewModel {
    private func saveCathedra() {
        if let _ = cathedraToBeEditedSubject.value {
            editCathedra()
        } else {
            createCathedra()
        }
    }
    
    private func createCathedra() {
        let cathedraName = cathedraNameSubject.value!
        let foundedDate = foundedDateSubject.value?.toStringFromISO8601()
        let siteUrl = siteUrlSubject.value
        let additionalInfo = additionalInfoSubject.value
        let facultyId = facultySubject.value.id
        
        App.shared.api.general.createCathedra(named: cathedraName, foundedDate: foundedDate, siteUrl: siteUrl, additionalInfo: additionalInfo, facultyId: facultyId)
            .asSingle()
            .subscribeOn(concurrentQueue)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { faculty in
                    self.cathedraManipulatedSubject.onNext(faculty)
                    self.cathedraManipulatedSubject.onCompleted()
                },
                onError: {
                    self.cathedraManipulatedSubject.onNext(nil)
                    self.errorSubject.accept($0)
                }
            ).disposed(by: requestDisposeBag)
    }
    
    private func editCathedra() {
        let cathedraId = cathedraToBeEditedSubject.value!.id
        let cathedraName = cathedraNameSubject.value!
        let foundedDate = foundedDateSubject.value?.toStringFromISO8601()
        let siteUrl = siteUrlSubject.value
        let additionalInfo = additionalInfoSubject.value
        let facultyId = facultySubject.value.id
        
        App.shared.api.general.editCathedra(id: cathedraId, name: cathedraName, foundedDate: foundedDate, siteUrl: siteUrl, additionalInfo: additionalInfo, facultyId: facultyId)
            .asSingle()
            .subscribeOn(concurrentQueue)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { faculty in
                    self.cathedraManipulatedSubject.onNext(faculty)
                    self.cathedraManipulatedSubject.onCompleted()
                },
                onError: {
                    self.cathedraManipulatedSubject.onNext(nil)
                    self.errorSubject.accept($0)
                }
            ).disposed(by: disposeBag)
    }
    
    private func deleteCathedra() {
        let cathedraId = cathedraToBeEditedSubject.value!.id
        
        App.shared.api.general.deleteCathedra(id: cathedraId)
            .asSingle()
            .subscribeOn(concurrentQueue)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { _ in
                    self.cathedraDeletedSubject.onNext(true)
                    self.cathedraDeletedSubject.onCompleted()
                },
                onError: {
                    self.cathedraDeletedSubject.onNext(false)
                    self.errorSubject.accept($0)
                }
            ).disposed(by: requestDisposeBag)
    }
    
    private func cancelRequests() {
        requestDisposeBag = DisposeBag()
    }
}
