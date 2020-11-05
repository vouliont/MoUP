import Foundation
import RxSwift
import RxCocoa

class LessonsListViewModel: BaseViewModel {
    
    let loadMoreLessonSubject = PublishSubject<Void>()
    
    private let currentPageSubject = BehaviorRelay<Int>(value: 0)
    private let totalPagesSubject = BehaviorRelay<Int>(value: 1)
    private let lessonCellsDataSubject = BehaviorRelay<[LessonCellData]>(value: [
        LessonCellData(item: nil, cellType: .loadingCell)
    ])
    private let loadingLessonsSubject = BehaviorRelay<Bool>(value: false)
    private let needInitializeLessonsListSubject = BehaviorRelay<Bool>(value: false)
    
    private var requestDisposeBag = DisposeBag()
    
    override init() {
        super.init()
        
        loadMoreLessonSubject
            .filter { [unowned self] in !self.loadingLessonsSubject.value }
            .map { [unowned self] in self.currentPageSubject.value + 1 }
            .bind(to: currentPageSubject)
            .disposed(by: disposeBag)
        
        loadMoreLessonSubject
            .map { true }
            .bind(to: loadingLessonsSubject)
            .disposed(by: disposeBag)
        
        lessonCellsDataSubject
            .map { _ in false }
            .bind(to: loadingLessonsSubject)
            .disposed(by: disposeBag)
        
        lessonCellsDataSubject
            .map { _ in false }
            .bind(to: needInitializeLessonsListSubject)
            .disposed(by: disposeBag)
        
        currentPageSubject
            .filter { $0 != 0 }
            .bind(onNext: loadLessons(for:))
            .disposed(by: disposeBag)
        
        needInitializeLessonsListSubject
            .filter { $0 }
            .map { _ in 0 }
            .bind(to: currentPageSubject)
            .disposed(by: disposeBag)
        needInitializeLessonsListSubject
            .filter { $0 }
            .map { _ in 1 }
            .bind(to: totalPagesSubject)
            .disposed(by: disposeBag)
    }
    
    func transform(input: Input) -> Output {
        input.viewDidAppear
            .withLatestFrom(needInitializeLessonsListSubject) { $1 }
            .filter { $0 }
            .map { _ in [LessonCellData(item: nil, cellType: .loadingCell)] }
            .bind(to: lessonCellsDataSubject)
            .disposed(by: disposeBag)
        
        input.viewDidDisappear
            .bind(to: needInitializeLessonsListSubject)
            .disposed(by: disposeBag)
        input.viewDidDisappear
            .map { _ in () }
            .bind(onNext: cancelRequests)
            .disposed(by: disposeBag)
        
        return Output(
            lessonCellsData: lessonCellsDataSubject.asDriver(),
            lessonSelected: input.cellDidSelect
                .map { [unowned self] in self.lessonCellsDataSubject.value[$0.row].item }
                .filter { $0 != nil }
                .map { $0! }
                .asDriver(onErrorDriveWith: Driver<Lesson>.empty())
        )
    }
    
}

// MARK: - INPUTS/OUTPUTS
extension LessonsListViewModel {
    struct Input {
        let viewDidAppear: ControlEvent<Bool>
        let viewDidDisappear: ControlEvent<Bool>
        let cellDidSelect: ControlEvent<IndexPath>
    }
    
    struct Output {
        let lessonCellsData: Driver<[LessonCellData]>
        let lessonSelected: Driver<Lesson>
    }
    
    struct Segue {
        static let showLesson = "showLessonSegue"
        static let createLesson = "createLessonSegue"
    }
}

// MARK: - HELPER FUNCTIONS
extension LessonsListViewModel {
    private func loadLessons(for page: Int) {
        App.shared.api.general.loadLessonsList(page: page)
            .asSingle()
            .subscribeOn(concurrentQueue)
            .observeOn(concurrentQueue)
            .subscribe(
                onSuccess: { [weak self] result in
                    guard let strongSelf = self else { return }
                    let (lessons, pagination) = result
                    strongSelf.totalPagesSubject.accept(pagination.totalPages)
                    
                    var lessonCellsData = strongSelf.lessonCellsDataSubject.value
                    if lessonCellsData.last?.cellType == CellType.loadingCell {
                        lessonCellsData.removeLast()
                    }
                    for lesson in lessons {
                        let lessonCellData = LessonCellData(item: lesson, cellType: .lessonCell)
                        lessonCellsData.append(lessonCellData)
                    }
                    if pagination.currentPage < pagination.totalPages {
                        let lessonCellData = LessonCellData(item: nil, cellType: .loadingCell)
                        lessonCellsData.append(lessonCellData)
                    }
                    
                    strongSelf.lessonCellsDataSubject.accept(lessonCellsData)
                },
                onError: { [weak self] in self?.errorSubject.accept($0) }
            )
            .disposed(by: requestDisposeBag)
    }
    
    func lessonDidCreate(lesson: Lesson) {
        currentPageSubject.accept(0)
        totalPagesSubject.accept(1)
        lessonCellsDataSubject.accept([
            LessonCellData(item: nil, cellType: .loadingCell)
        ])
    }
    
    private func cancelRequests() {
        requestDisposeBag = DisposeBag()
    }
}
