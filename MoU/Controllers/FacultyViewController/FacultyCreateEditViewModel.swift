import UIKit
import RxSwift
import RxCocoa

class FacultyCreateEditViewModel: BaseViewModel {
    
    let facultyToBeEditedSubject: BehaviorRelay<Faculty?>
    
    private let navItemTitleSubject = BehaviorRelay<String>(value: "")
    private let saveBarButtonItemSubject = BehaviorRelay<UIBarButtonItem?>(value: nil)
    
    private let facultyNameSubject = BehaviorRelay<String?>(value: nil)
    private let foundedDateSubject = BehaviorRelay<Date?>(value: nil)
    private let siteUrlSubject = BehaviorRelay<String?>(value: nil)
    private let additionalInfoSubject = BehaviorRelay<String?>(value: nil)
    
    private let foundedDateEditingSubject = BehaviorRelay<Bool>(value: false)
    
    let facultyManipulatedSubject = PublishSubject<Faculty?>()
    let facultyDeletedSubject = PublishSubject<Bool>()
    
    private var requestDisposeBag = DisposeBag()
    
    let minimumDate: Date = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        return dateFormatter.date(from: "01.01.1990")!
    }()
    let maximumDate = Date()
    
    init(facultyToBeEdit: Faculty?) {
        facultyToBeEditedSubject = BehaviorRelay(value: facultyToBeEdit)
        
        super.init()
        
        facultyToBeEditedSubject
            .map { $0 == nil ? "NEW_FACULTY_TITLE".localized : "EDIT_FACULTY_TITLE".localized }
            .bind(to: navItemTitleSubject)
            .disposed(by: disposeBag)
        
        facultyToBeEditedSubject
            .filter { $0 != nil }
            .map { $0!.name }
            .bind(to: facultyNameSubject)
            .disposed(by: disposeBag)
        facultyToBeEditedSubject
            .map { $0?.foundedDate }
            .bind(to: foundedDateSubject)
            .disposed(by: disposeBag)
        facultyToBeEditedSubject
            .map { $0?.siteUrl }
            .bind(to: siteUrlSubject)
            .disposed(by: disposeBag)
        facultyToBeEditedSubject
            .map { $0?.additionalInfo }
            .bind(to: additionalInfoSubject)
            .disposed(by: disposeBag)
    }
    
    func transform(input: Input) -> Output {
        input.saveTrigger
            .bind(onNext: saveFaculty)
            .disposed(by: disposeBag)
        
        input.cancelTrigger
            .bind(onNext: {
                self.facultyManipulatedSubject.onCompleted()
            })
            .disposed(by: disposeBag)
        
        input.deleteTrigger
            .bind(onNext: deleteFaculty)
            .disposed(by: disposeBag)
        
        input.facultyNameChanged
            .skip(1)
            .map { $0 ?? "" }
            .bind(to: facultyNameSubject)
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
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd.MM.yyyy"
                guard let dateString = dateString,
                    let date = dateFormatter.date(from: dateString)
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
            saveBarButtonItemEnabled: facultyNameSubject
                .map { $0?.count ?? 0 >= 6 }
                .asDriver(onErrorJustReturn: false),
            facultyName: facultyNameSubject.asDriver(),
            foundedDate: foundedDateSubject
                .filter { $0 != nil}
                .map({ date in
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd.MM.yyyy"
                    return dateFormatter.string(from: date!)
                })
                .asDriver(onErrorJustReturn: ""),
            siteUrl: siteUrlSubject.asDriver(),
            additionalInfo: additionalInfoSubject.asDriver(),
            facultyDidManipulate: facultyManipulatedSubject.asDriver(onErrorJustReturn: nil),
            datePickerValue: foundedDateSubject
                .filter { _ in !self.foundedDateEditingSubject.value }
                .map { $0 ?? Date() }
                .asDriver(onErrorJustReturn: Date()),
            deleteButtonVisible: facultyToBeEditedSubject
                .map { $0 != nil }
                .asDriver(onErrorJustReturn: false)
        )
    }
    
}

// MARK: - INPUTS/OUTPUTS
extension FacultyCreateEditViewModel {
    struct Input {
        let saveTrigger: ControlEvent<Void>
        let cancelTrigger: ControlEvent<Void>
        let deleteTrigger: ControlEvent<Void>
        let facultyNameChanged: ControlProperty<String?>
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
        let facultyName: Driver<String?>
        let foundedDate: Driver<String?>
        let siteUrl: Driver<String?>
        let additionalInfo: Driver<String?>
        let facultyDidManipulate: Driver<Faculty?>
        let datePickerValue: Driver<Date>
        let deleteButtonVisible: Driver<Bool>
    }
}

// MARK: - HELPER FUNCTIONS
extension FacultyCreateEditViewModel {
    
    private func saveFaculty() {
        if let _ = facultyToBeEditedSubject.value {
            editFaculty()
        } else {
            createFaculty()
        }
    }
    
    private func createFaculty() {
        let facultyName = facultyNameSubject.value!
        let foundedDate = foundedDateSubject.value?.toStringFromISO8601()
        let siteUrl = siteUrlSubject.value
        let additionalInfo = additionalInfoSubject.value
        
        App.shared.api.general.createFaculty(named: facultyName, foundedDate: foundedDate, siteUrl: siteUrl, additionalInfo: additionalInfo)
            .asSingle()
            .subscribeOn(concurrentQueue)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { faculty in
                    self.facultyManipulatedSubject.onNext(faculty)
                    self.facultyManipulatedSubject.onCompleted()
                },
                onError: {
                    self.facultyManipulatedSubject.onNext(nil)
                    self.errorSubject.accept($0)
                }
            ).disposed(by: requestDisposeBag)
    }
    
    private func editFaculty() {
        let facultyId = facultyToBeEditedSubject.value!.id
        let facultyName = facultyNameSubject.value!
        let foundedDate = foundedDateSubject.value?.toStringFromISO8601()
        let siteUrl = siteUrlSubject.value
        let additionalInfo = additionalInfoSubject.value
        
        App.shared.api.general.editFaculty(id: facultyId, name: facultyName, foundedDate: foundedDate, siteUrl: siteUrl, additionalInfo: additionalInfo)
            .asSingle()
            .subscribeOn(concurrentQueue)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { faculty in
                    self.facultyManipulatedSubject.onNext(faculty)
                    self.facultyManipulatedSubject.onCompleted()
                },
                onError: {
                    self.facultyManipulatedSubject.onNext(nil)
                    self.errorSubject.accept($0)
                }
            ).disposed(by: disposeBag)
    }
    
    private func deleteFaculty() {
        let facultyId = facultyToBeEditedSubject.value!.id
        
        App.shared.api.general.deleteFaculty(id: facultyId)
            .asSingle()
            .subscribeOn(concurrentQueue)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { _ in
                    self.facultyDeletedSubject.onNext(true)
                    self.facultyDeletedSubject.onCompleted()
                },
                onError: {
                    self.facultyDeletedSubject.onNext(false)
                    self.errorSubject.accept($0)
                }
            ).disposed(by: requestDisposeBag)
    }
    
    private func cancelRequests() {
        requestDisposeBag = DisposeBag()
    }
    
}
