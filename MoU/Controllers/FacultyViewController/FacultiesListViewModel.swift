import Foundation
import RxSwift
import RxCocoa

class FacultiesListViewModel: BaseViewModel {
    
    let loadMoreFacultySubject = PublishSubject<Void>()
    
    private let currentPageSubject = BehaviorRelay<Int>(value: 0)
    private let totalPagesSubject = BehaviorRelay<Int>(value: 1)
    private let facultyCellsDataSubject = BehaviorRelay<[FacultyCellData]>(value: [
        FacultyCellData(item: nil, cellType: .loadingCell)
    ])
    private let loadingFacultiesSubject = BehaviorRelay<Bool>(value: false)
    private let needInitializeFacultiesListSubject = BehaviorRelay<Bool>(value: false)
    
    private var requestDisposeBag = DisposeBag()
    
    override init() {
        super.init()
        
        loadMoreFacultySubject
            .filter { [unowned self] in !self.loadingFacultiesSubject.value }
            .map { [unowned self] in self.currentPageSubject.value + 1 }
            .bind(to: currentPageSubject)
            .disposed(by: disposeBag)
        
        loadMoreFacultySubject
            .map { true }
            .bind(to: loadingFacultiesSubject)
            .disposed(by: disposeBag)
        
        facultyCellsDataSubject
            .skip(1)
            .map { _ in false }
            .bind(to: loadingFacultiesSubject)
            .disposed(by: disposeBag)
        
        facultyCellsDataSubject
            .map { _ in false }
            .bind(to: needInitializeFacultiesListSubject)
            .disposed(by: disposeBag)
        
        currentPageSubject
            .filter { $0 != 0 }
            .bind(onNext: { [unowned self] in
                self.loadFaculties(for: $0)
            })
            .disposed(by: disposeBag)
        
        needInitializeFacultiesListSubject
            .filter { $0 }
            .map { _ in 0 }
            .bind(to: currentPageSubject)
            .disposed(by: disposeBag)
        needInitializeFacultiesListSubject
            .filter { $0 }
            .map { _ in 1 }
            .bind(to: totalPagesSubject)
            .disposed(by: disposeBag)
    }
    
    func transform(input: Input) -> Output {
        input.viewDidAppear
            .withLatestFrom(needInitializeFacultiesListSubject) { $1 }
            .filter { $0 }
            .map { _ in [FacultyCellData(item: nil, cellType: .loadingCell)] }
            .bind(to: facultyCellsDataSubject)
            .disposed(by: disposeBag)
        
        input.viewDidDisappear
            .bind(to: needInitializeFacultiesListSubject)
            .disposed(by: disposeBag)
        input.viewDidDisappear
            .map { _ in () }
            .bind(onNext: { [unowned self] in
                self.cancelRequests()
            })
            .disposed(by: disposeBag)
        
        return Output(
            facultyCellsData: facultyCellsDataSubject.asDriver(),
            facultySelected: input.cellDidSelect
                .map { [unowned self] in self.facultyCellsDataSubject.value[$0.row].item }
                .filter { $0 != nil }
                .map { $0! }
                .asDriver(onErrorDriveWith: Driver<Faculty>.empty())
        )
    }
    
}

// MARK: - INPUTS/OUTPUTS
extension FacultiesListViewModel {
    struct Input {
        let viewDidAppear: ControlEvent<Bool>
        let viewDidDisappear: ControlEvent<Bool>
        let cellDidSelect: ControlEvent<IndexPath>
    }
    
    struct Output {
        let facultyCellsData: Driver<[FacultyCellData]>
        let facultySelected: Driver<Faculty>
    }
    
    struct Segue {
        static let showFaculty = "showFacultySegue"
        static let createFaculty = "createFacultySegue"
        static let createCathedra = "createCathedraSegue"
    }
}

// MARK: - HELPER FUNCTIONS
extension FacultiesListViewModel {
    private func loadFaculties(for page: Int) {
        App.shared.api.general.loadFacultiesList(page: page)
            .asSingle()
            .subscribeOn(concurrentQueue)
            .observeOn(concurrentQueue)
            .subscribe(
                onSuccess: { [weak self] result in
                    guard let strongSelf = self else { return }
                    let (faculties, pagination) = result
                    strongSelf.totalPagesSubject.accept(pagination.totalPages)
                    
                    var facultyCellsData = strongSelf.facultyCellsDataSubject.value
                    if facultyCellsData.last?.cellType == CellType.loadingCell {
                        facultyCellsData.removeLast()
                    }
                    for faculty in faculties {
                        let facultyCellData = FacultyCellData(item: faculty, cellType: .facultyCell)
                        facultyCellsData.append(facultyCellData)
                    }
                    if pagination.currentPage < pagination.totalPages {
                        let facultyCellData = FacultyCellData(item: nil, cellType: .loadingCell)
                        facultyCellsData.append(facultyCellData)
                    }
                    
                    strongSelf.facultyCellsDataSubject.accept(facultyCellsData)
                },
                onError: { [weak self] in self?.errorSubject.accept($0) }
            )
            .disposed(by: requestDisposeBag)
    }
    
    func facultyDidCreate(faculty: Faculty) {
        currentPageSubject.accept(0)
        totalPagesSubject.accept(1)
        facultyCellsDataSubject.accept([
            FacultyCellData(item: nil, cellType: .loadingCell)
        ])
    }
    
    private func cancelRequests() {
        requestDisposeBag = DisposeBag()
    }
}
