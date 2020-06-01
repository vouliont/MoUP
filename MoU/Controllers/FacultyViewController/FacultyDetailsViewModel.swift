import Foundation
import RxSwift
import RxCocoa

class FacultyDetailsViewModel: BaseViewModel {
    
    let loadMoreCathedrasSubject = PublishSubject<Void>()
    
    private let currentPageSubject = BehaviorRelay<Int>(value: 0)
    private let totalPagesSubject = BehaviorRelay<Int>(value: 1)
    
    let facultySubject: BehaviorRelay<Faculty>
    private let facultyNameSubject = BehaviorRelay<String>(value: "")
    private let formattedFoundedDateSubject = BehaviorRelay<String>(value: "")
    private let linkSubject = BehaviorRelay<String>(value: "")
    private let additionalInfoSubject = BehaviorRelay<String>(value: "")
    
    private let needInitializeCathedrasListSubject = BehaviorRelay<Bool>(value: false)
    private let loadingCathedrasSubject = BehaviorRelay<Bool>(value: false)
    private let cathedraCellsDataSubject = BehaviorRelay<[CathedraCellData]>(value: [
        CathedraCellData(item: nil, cellType: .loadingCell)
    ])
    
    private var requestDisposeBag = DisposeBag()
    
    init(faculty: Faculty) {
        facultySubject = BehaviorRelay(value: faculty)
        
        super.init()
        
        currentPageSubject
            .filter { $0 != 0 }
            .bind(onNext: loadMoreCathedras(for:))
            .disposed(by: disposeBag)
        
        loadMoreCathedrasSubject
            .map { self.currentPageSubject.value + 1 }
            .bind(to: currentPageSubject)
            .disposed(by: disposeBag)
        
        loadMoreCathedrasSubject
            .map { true }
            .bind(to: loadingCathedrasSubject)
            .disposed(by: disposeBag)
        
        cathedraCellsDataSubject
            .map { _ in false }
            .bind(to: loadingCathedrasSubject)
            .disposed(by: disposeBag)
        
        cathedraCellsDataSubject
            .map { _ in false }
            .bind(to: needInitializeCathedrasListSubject)
            .disposed(by: disposeBag)
        
        facultySubject
            .map { $0.name }
            .bind(to: facultyNameSubject)
            .disposed(by: disposeBag)
        facultySubject
            .map { $0.foundedDate }
            .map { date in
                guard let date = date else { return "" }
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d, yyyy" // May 10, 2020
                return String(format: "FROM_DATE".localized, formatter.string(from: date))
            }
            .bind(to: formattedFoundedDateSubject)
            .disposed(by: disposeBag)
        facultySubject
            .map { $0.siteUrl ?? "" }
            .bind(to: linkSubject)
            .disposed(by: disposeBag)
        facultySubject
            .map { $0.additionalInfo ?? "" }
            .bind(to: additionalInfoSubject)
            .disposed(by: disposeBag)
        
        needInitializeCathedrasListSubject
            .filter { $0 }
            .map { _ in 0 }
            .bind(to: currentPageSubject)
            .disposed(by: disposeBag)
        needInitializeCathedrasListSubject
            .filter { $0 }
            .map { _ in 1 }
            .bind(to: totalPagesSubject)
            .disposed(by: disposeBag)
    }
    
    func transform(input: Input) -> Output {
        input.viewDidAppear
            .withLatestFrom(needInitializeCathedrasListSubject) { $1 }
            .filter { $0 }
            .map { _ in [CathedraCellData(item: nil, cellType: .loadingCell)] }
            .bind(to: cathedraCellsDataSubject)
            .disposed(by: disposeBag)
        
        input.viewDidDisappear
            .map { _ in () }
            .bind(onNext: cancelRequests)
            .disposed(by: disposeBag)
        input.viewDidDisappear
            .bind(to: needInitializeCathedrasListSubject)
            .disposed(by: disposeBag)
        
        return Output(
            facultyName: facultyNameSubject.asDriver(),
            formattedFoundedDate: formattedFoundedDateSubject.asDriver(),
            dateVisible: formattedFoundedDateSubject
                .map { !$0.isEmpty }
                .asDriver(onErrorJustReturn: false),
            linkVisible: linkSubject
                .map { !$0.isEmpty }
                .asDriver(onErrorJustReturn: false),
            additionalInfo: additionalInfoSubject.asDriver(),
            additionalInfoVisible: additionalInfoSubject
                .map { !$0.isEmpty }
                .asDriver(onErrorJustReturn: false),
            cathedraCellsData: cathedraCellsDataSubject.asDriver()
        )
    }
    
}

// MARK: - INPUTS/OUTPUTS
extension FacultyDetailsViewModel {
    struct Input {
        let viewDidAppear: ControlEvent<Bool>
        let viewDidDisappear: ControlEvent<Bool>
    }
    
    struct Output {
        let facultyName: Driver<String>
        let formattedFoundedDate: Driver<String>
        let dateVisible: Driver<Bool>
        let linkVisible: Driver<Bool>
        let additionalInfo: Driver<String>
        let additionalInfoVisible: Driver<Bool>
        let cathedraCellsData: Driver<[CathedraCellData]>
    }
    
    struct Segue {
        static let editFaculty = "editFacultySegue"
        static let cathedraDetails = "cathedraDetailsSegue"
        static let createCathedra = "createCathedraSegue"
    }
}

// MARK: - HELPER FUNCTIONS
extension FacultyDetailsViewModel {
    
    private func loadMoreCathedras(for page: Int) {
        let facultyId = facultySubject.value.id
        
        App.shared.api.general.loadCathedrasList(facultyId: facultyId, page: page)
            .asSingle()
            .subscribe(
                onSuccess: { result in
                    let (cathedras, pagination) = result
                    self.totalPagesSubject.accept(pagination.totalPages)
                    
                    var cathedraCellsData = self.cathedraCellsDataSubject.value
                    if cathedraCellsData.last?.cellType == CellType.loadingCell {
                        cathedraCellsData.removeLast()
                    }
                    for cathedra in cathedras {
                        let cathedraCellData = CathedraCellData(item: cathedra, cellType: .cathedraCell)
                        cathedraCellsData.append(cathedraCellData)
                    }
                    if pagination.currentPage < pagination.totalPages {
                        let loadingCellData = CathedraCellData(item: nil, cellType: .loadingCell)
                        cathedraCellsData.append(loadingCellData)
                    }
                    self.cathedraCellsDataSubject.accept(cathedraCellsData)
                },
                onError: { error in
                    self.errorSubject.accept(error)
                }
            )
            .disposed(by: requestDisposeBag)
    }
    
    func facultyDidEdit(faculty: Faculty) {
        facultySubject.accept(faculty)
        currentPageSubject.accept(0)
        totalPagesSubject.accept(1)
        cathedraCellsDataSubject.accept([
            CathedraCellData(item: nil, cellType: .loadingCell)
        ])
    }
    
    func cathedraDidCreate(cathedra: Cathedra) {
        currentPageSubject.accept(0)
        totalPagesSubject.accept(1)
        cathedraCellsDataSubject.accept([
            CathedraCellData(item: nil, cellType: .loadingCell)
        ])
    }
    
    func cathedra(for indexPath: IndexPath) -> Cathedra {
        return cathedraCellsDataSubject.value[indexPath.row].item!
    }
    
    private func cancelRequests() {
        requestDisposeBag = DisposeBag()
    }
    
}
