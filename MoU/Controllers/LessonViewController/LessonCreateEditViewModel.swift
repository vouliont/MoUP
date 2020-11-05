import Foundation
import RxSwift
import RxCocoa

class LessonCreateEditViewModel: BaseViewModel {
    
    private let navItemTitleSubject: BehaviorRelay<String>
    
    let lessonToBeEditedSubject: BehaviorRelay<Lesson?>
    
    private let lessonNameSubject: BehaviorRelay<String?>
    private let teacherSubject: BehaviorRelay<Teacher?>
    
    private let loadingBarIndicatorVisibleSubject = BehaviorRelay<Bool>(value: false)
    
    private let didManipulateSuccessfullySubject = PublishRelay<Bool>()
    
    private let lessonManipulatedListener: PublishRelay<Lesson>?
    private let lessonDeletedListener: PublishRelay<Void>?
    
    private var requestDisposeBag = DisposeBag()
    
    init(
        lessonToBeEdit: Lesson?,
        lessonManipulatedListener: PublishRelay<Lesson>? = nil,
        lessonDeletedListener: PublishRelay<Void>? = nil
    ) {
        navItemTitleSubject = BehaviorRelay(value: lessonToBeEdit == nil ? "NEW_LESSON_TITLE".localized : "EDIT_LESSON_TITLE".localized)
        
        lessonToBeEditedSubject = BehaviorRelay(value: lessonToBeEdit)
        
        lessonNameSubject = BehaviorRelay(value: lessonToBeEdit?.name)
        teacherSubject = BehaviorRelay(value: lessonToBeEdit?.teacher)
        
        self.lessonManipulatedListener = lessonManipulatedListener
        self.lessonDeletedListener = lessonDeletedListener
        
        super.init()
    }
    
    func transform(input: Input) -> Output {
        input.saveTrigger
            .bind(onNext: saveLesson)
            .disposed(by: disposeBag)
        
        input.deleteTrigger
            .bind(onNext: deleteLesson)
            .disposed(by: disposeBag)
        
        input.lessonNameChanged
            .map { $0 ?? "" }
            .bind(to: lessonNameSubject)
            .disposed(by: disposeBag)
        
        input.viewDidDissapear
            .map { _ in () }
            .bind(onNext: cancelRequests)
            .disposed(by: disposeBag)
        
        errorSubject
            .map { _ in false }
            .bind(to: loadingBarIndicatorVisibleSubject)
            .disposed(by: disposeBag)
        
        return Output(
            navItemTitle: navItemTitleSubject.asDriver(),
            saveBarButtonItemEnabled: Driver.combineLatest(lessonNameSubject.asDriver(), teacherSubject.asDriver()) { lessonName, teacher in
                lessonName?.count ?? 0 >= 6 && teacher != nil
            },
            lessonName: lessonNameSubject.asDriver(),
            teacherName: teacherSubject
                .map { $0?.fullName ?? "" }
                .asDriver(onErrorJustReturn: ""),
            loadingBarIndicatorVisible: loadingBarIndicatorVisibleSubject.asDriver(),
            deleteButtonVisible: lessonToBeEditedSubject
                .map { $0 != nil }
                .asDriver(onErrorJustReturn: false),
            didManipulateSuccessfully: didManipulateSuccessfullySubject
                .asDriver(onErrorJustReturn: false)
        )
    }
    
}

// MARK: - INPUTS/OUTPUTS
extension LessonCreateEditViewModel {
    struct Input {
        let saveTrigger: ControlEvent<Void>
        let deleteTrigger: ControlEvent<Void>
        let lessonNameChanged: ControlProperty<String?>
        let viewDidDissapear: ControlEvent<Bool>
    }
    
    struct Output {
        let navItemTitle: Driver<String>
        let saveBarButtonItemEnabled: Driver<Bool>
        let lessonName: Driver<String?>
        let teacherName: Driver<String?>
        let loadingBarIndicatorVisible: Driver<Bool>
        let deleteButtonVisible: Driver<Bool>
        let didManipulateSuccessfully: Driver<Bool>
    }
}

// MARK: - HELPER FUNCTIONS
extension LessonCreateEditViewModel {
    private func saveLesson() {
        if let _ = lessonToBeEditedSubject.value {
            editLesson()
        } else {
            createLesson()
        }
    }
    
    private func createLesson() {
        let lessonName = lessonNameSubject.value!
        let teacherId = teacherSubject.value!.id
        
        App.shared.api.general.createLesson(named: lessonName, teacherId: teacherId)
            .asSingle()
            .subscribeOn(concurrentQueue)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] in
                    self?.lessonManipulatedListener?.accept($0)
                    self?.didManipulateSuccessfullySubject.accept(true)
                },
                onError: { [weak self] in
                    self?.errorSubject.accept($0)
                    self?.didManipulateSuccessfullySubject.accept(false)
                }
            ).disposed(by: requestDisposeBag)
    }
    
    private func editLesson() {
        let lessonId = lessonToBeEditedSubject.value!.id
        let lessonName = lessonNameSubject.value!
        let teacherId = teacherSubject.value!.id
        
        App.shared.api.general.editLesson(id: lessonId, name: lessonName, teacherId: teacherId)
            .asSingle()
            .subscribeOn(concurrentQueue)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] in
                    self?.lessonManipulatedListener?.accept($0)
                    self?.didManipulateSuccessfullySubject.accept(true)
                },
                onError: { [weak self] in
                    self?.errorSubject.accept($0)
                    self?.didManipulateSuccessfullySubject.accept(false)
                }
            ).disposed(by: requestDisposeBag)
    }
    
    private func deleteLesson() {
        let lessonId = lessonToBeEditedSubject.value!.id
        
        App.shared.api.general.deleteLesson(id: lessonId)
            .asSingle()
            .subscribeOn(concurrentQueue)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] in
                    self?.lessonDeletedListener?.accept(())
                    self?.didManipulateSuccessfullySubject.accept(true)
                },
                onError: { [weak self] in
                    self?.errorSubject.accept($0)
                    self?.didManipulateSuccessfullySubject.accept(false)
                }
            ).disposed(by: requestDisposeBag)
    }
    
    private func cancelRequests() {
        requestDisposeBag = DisposeBag()
    }
}
