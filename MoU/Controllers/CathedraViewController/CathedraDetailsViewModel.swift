import Foundation
import RxSwift
import RxCocoa

class CathedraDetailsViewModel: BaseViewModel {
    
    let cathedraSubject: BehaviorRelay<Cathedra>
    let facultySubject: BehaviorRelay<Faculty>
    
    let loadMoreGroupsSubject = PublishSubject<Void>()
    
    private let currentPageSubject = BehaviorRelay<Int>(value: 0)
    private let totalPagesSubject = BehaviorRelay<Int>(value: 1)
    
    private let needInitializeGroupsListSubject = BehaviorRelay<Bool>(value: false)
    private let loadingGroupsSubject = BehaviorRelay<Bool>(value: false)
    private let groupCellsDataSubject = BehaviorRelay<[GroupCellData]>(value: [
        GroupCellData(item: nil, cellType: .loadingCell)
    ])
    
    private var requestDisposeBag = DisposeBag()
    
    init(cathedra: Cathedra, on faculty: Faculty) {
        cathedraSubject = BehaviorRelay(value: cathedra)
        facultySubject = BehaviorRelay(value: faculty)
        
        super.init()
        
        currentPageSubject
            .filter { $0 != 0 }
            .bind(onNext: loadMoreGroups(for:))
            .disposed(by: disposeBag)
        
        loadMoreGroupsSubject
            .map { self.currentPageSubject.value + 1 }
            .bind(to: currentPageSubject)
            .disposed(by: disposeBag)
        
        loadMoreGroupsSubject
            .map { true }
            .bind(to: loadingGroupsSubject)
            .disposed(by: disposeBag)
        
        groupCellsDataSubject
            .map { _ in false }
            .bind(to: loadingGroupsSubject)
            .disposed(by: disposeBag)
        
        groupCellsDataSubject
            .map { _ in false }
            .bind(to: needInitializeGroupsListSubject)
            .disposed(by: disposeBag)
        
        needInitializeGroupsListSubject
            .filter { $0 }
            .map { _ in 0 }
            .bind(to: currentPageSubject)
            .disposed(by: disposeBag)
        needInitializeGroupsListSubject
            .filter { $0 }
            .map { _ in 1 }
            .bind(to: totalPagesSubject)
            .disposed(by: disposeBag)
    }
    
    func translate(input: Input) -> Output {
        input.viewDidAppear
            .withLatestFrom(needInitializeGroupsListSubject) { $1 }
            .filter { $0 }
            .map { _ in [GroupCellData(item: nil, cellType: .loadingCell)] }
            .bind(to: groupCellsDataSubject)
            .disposed(by: disposeBag)
        
        input.viewDidDisappear
            .map { _ in () }
            .bind(onNext: cancelRequests)
            .disposed(by: disposeBag)
        input.viewDidDisappear
            .bind(to: needInitializeGroupsListSubject)
            .disposed(by: disposeBag)
        
        return Output(
            cathedraName: cathedraSubject
                .map { $0.name }
                .asDriver(onErrorJustReturn: ""),
            formattedFoundedDate: cathedraSubject
                .filter { $0.foundedDate != nil }
                .map({
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM d, yyyy" // May 10, 2020
                    let dateString = formatter.string(from: $0.foundedDate!)
                    return String(format: "FROM_DATE".localized, dateString)
                })
                .asDriver(onErrorJustReturn: ""),
            dateVisible: cathedraSubject
                .map { $0.foundedDate != nil }
                .asDriver(onErrorJustReturn: false),
            linkVisible: cathedraSubject
                .map { $0.siteUrl != nil }
                .asDriver(onErrorJustReturn: false),
            additionalInfo: cathedraSubject
                .filter { $0.additionalInfo != nil }
                .map { $0.additionalInfo! }
                .asDriver(onErrorJustReturn: ""),
            additionalInfoVisible: cathedraSubject
                .map { $0.additionalInfo != nil }
                .asDriver(onErrorJustReturn: false),
            groupCellsData: groupCellsDataSubject.asDriver()
        )
    }
}

// MARK: - INPUTS/OUTPUTS
extension CathedraDetailsViewModel {
    struct Input {
        let viewDidAppear: ControlEvent<Bool>
        let viewDidDisappear: ControlEvent<Bool>
    }
    struct Output {
        let cathedraName: Driver<String>
        let formattedFoundedDate: Driver<String>
        let dateVisible: Driver<Bool>
        let linkVisible: Driver<Bool>
        let additionalInfo: Driver<String>
        let additionalInfoVisible: Driver<Bool>
        let groupCellsData: Driver<[GroupCellData]>
    }
    
    struct Segue {
        static let groupDetails = "groupDetailsSegue"
        static let editCathedra = "editCathedraSegue"
        static let createGroup = "createGroupSegue"
    }
}

// MARK: - HELPER FUNCTIONS
extension CathedraDetailsViewModel {
    private func loadMoreGroups(for page: Int) {
        let cathedraId = cathedraSubject.value.id
        
        App.shared.api.general.loadGroupsList(forCathedraId: cathedraId, page: page)
            .asSingle()
            .subscribe(
                onSuccess: { result in
                    let (groups, pagination) = result
                    self.totalPagesSubject.accept(pagination.totalPages)
                    
                    var groupCellsData = self.groupCellsDataSubject.value
                    if groupCellsData.last?.cellType == CellType.loadingCell {
                        groupCellsData.removeLast()
                    }
                    for group in groups {
                        let groupCellData = GroupCellData(item: group, cellType: .groupCell)
                        groupCellsData.append(groupCellData)
                    }
                    if pagination.currentPage < pagination.totalPages {
                        let loadingCellData = GroupCellData(item: nil, cellType: .loadingCell)
                        groupCellsData.append(loadingCellData)
                    }
                    self.groupCellsDataSubject.accept(groupCellsData)
                },
                onError: { error in
                    self.errorSubject.accept(error)
                }
            )
            .disposed(by: requestDisposeBag)
    }
    
    func cathedraDidEdit(cathedra: Cathedra) {
        cathedraSubject.accept(cathedra)
        currentPageSubject.accept(0)
        totalPagesSubject.accept(1)
        groupCellsDataSubject.accept([
            GroupCellData(item: nil, cellType: .loadingCell)
        ])
    }
    
    func group(for indexPath: IndexPath) -> Group {
        return groupCellsDataSubject.value[indexPath.row].item!
    }
    
    private func cancelRequests() {
        requestDisposeBag = DisposeBag()
    }
}
