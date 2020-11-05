import Foundation
import RxSwift
import RxCocoa

class GroupCreateEditViewModel: BaseViewModel {
    
    let groupToBeEditedSubject: BehaviorRelay<Group?>
    private let cathedraSubject: BehaviorRelay<Cathedra>
    
    private let navItemTitleSubject: BehaviorRelay<String>
    
    private let groupNameSubject: BehaviorRelay<String>
    private let semesterNumberSubject: BehaviorRelay<Int>
    
    let groupManipulatedSubject = PublishSubject<Group?>()
    let groupDeletedSubject = PublishSubject<Bool>()
    
    private var requestsDisposeBag = DisposeBag()
    
    init(groupToBeEdited: Group?, on cathedra: Cathedra) {
        groupToBeEditedSubject = BehaviorRelay(value: groupToBeEdited)
        cathedraSubject = BehaviorRelay(value: cathedra)
        
        groupNameSubject = BehaviorRelay(value: groupToBeEdited?.name ?? "")
        semesterNumberSubject = BehaviorRelay(value: groupToBeEdited?.numberOfSemesters ?? 0)
        
        navItemTitleSubject = BehaviorRelay(value: groupToBeEdited == nil ? "NEW_GROUP_TITLE".localized : "EDIT_GROUP_TITLE".localized)
        
        super.init()
    }
    
    func transform(input: Input) -> Output {
        input.saveTrigger
            .bind(onNext: { [unowned self] in
                self.saveGroup()
            })
            .disposed(by: disposeBag)
        
        input.cancelTrigger
            .bind(onNext: { [unowned self] in
                self.groupManipulatedSubject.onCompleted()
            })
            .disposed(by: disposeBag)
        
        input.deleteTrigger
            .bind(onNext: deleteGroup)
            .disposed(by: disposeBag)
        
        input.viewDidDissapear
            .map { _ in () }
            .bind(onNext: cancelRequests)
            .disposed(by: disposeBag)
        
        return Output(
            groupName: groupNameSubject.asDriver(),
            semesterNumber: semesterNumberSubject
                .map { "\($0)" }
                .asDriver(onErrorJustReturn: ""),
            navItemTitle: navItemTitleSubject.asDriver(),
            saveBarButtonItemEnabled: groupNameSubject
                .map { $0.count >= 6 }
                .asDriver(onErrorJustReturn: false),
            groupDidManipulate: groupManipulatedSubject.asDriver(onErrorJustReturn: nil),
            deleteButtonVisible: groupToBeEditedSubject
                .map { $0 != nil }
                .asDriver(onErrorJustReturn: false)
        )
    }
    
}

// MARK: - INPUTS/OUTPUTS
extension GroupCreateEditViewModel {
    struct Input {
        let groupNameChanged: ControlProperty<String?>
        let semesterNumberChanged: ControlProperty<String?>
        let saveTrigger: ControlEvent<Void>
        let cancelTrigger: ControlEvent<Void>
        let deleteTrigger: ControlEvent<Void>
        let viewDidDissapear: ControlEvent<Bool>
    }
    
    struct Output {
        let groupName: Driver<String>
        let semesterNumber: Driver<String>
        let navItemTitle: Driver<String>
        let saveBarButtonItemEnabled: Driver<Bool>
        let groupDidManipulate: Driver<Group?>
        let deleteButtonVisible: Driver<Bool>
    }
}

// MARK: - HELPER FUNCTIONS
extension GroupCreateEditViewModel {
    private func saveGroup() {
        if let _ = groupToBeEditedSubject.value {
            editGroup()
        } else {
            createGroup()
        }
    }
    
    private func createGroup() {
        let groupName = groupNameSubject.value
        let semesterNumber = semesterNumberSubject.value
        let cathedraId = cathedraSubject.value.id
        
        App.shared.api.general.createGroup(named: groupName, numberOfSemesters: semesterNumber, cathedraId: cathedraId)
            .asSingle()
            .subscribeOn(concurrentQueue)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] group in
                    self?.groupManipulatedSubject.onNext(group)
                    self?.groupManipulatedSubject.onCompleted()
                },
                onError: { [weak self] in
                    self?.groupManipulatedSubject.onNext(nil)
                    self?.errorSubject.accept($0)
                }
            ).disposed(by: requestsDisposeBag)
    }
    
    private func editGroup() {
        let groupId = groupToBeEditedSubject.value!.id
        let groupName = groupNameSubject.value
        let semesterNumber = semesterNumberSubject.value
        let cathedraId = cathedraSubject.value.id
        
        App.shared.api.general.editGroup(id: groupId, name: groupName, numberOfSemesters: semesterNumber, cathedraId: cathedraId)
            .asSingle()
            .subscribeOn(concurrentQueue)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] group in
                    self?.groupManipulatedSubject.onNext(group)
                    self?.groupManipulatedSubject.onCompleted()
                },
                onError: { [weak self] in
                    self?.groupManipulatedSubject.onNext(nil)
                    self?.errorSubject.accept($0)
                }
            ).disposed(by: requestsDisposeBag)
    }
    
    private func deleteGroup() {
        let groupId = groupToBeEditedSubject.value!.id
        
        App.shared.api.general.deleteGroup(id: groupId)
            .asSingle()
            .subscribeOn(concurrentQueue)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] _ in
                    self?.groupDeletedSubject.onNext(true)
                    self?.groupDeletedSubject.onCompleted()
                },
                onError: { [weak self] in
                    self?.groupDeletedSubject.onNext(false)
                    self?.errorSubject.accept($0)
                }
            ).disposed(by: requestsDisposeBag)
    }
    
    
    private func cancelRequests() {
        requestsDisposeBag = DisposeBag()
    }
}
