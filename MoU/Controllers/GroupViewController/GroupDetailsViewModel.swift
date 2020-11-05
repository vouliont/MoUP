import Foundation
import RxSwift
import RxCocoa

class GroupDetailsViewModel: BaseViewModel {
    
    private let currentPage = BehaviorRelay<Int>(value: 0)
    private let totalPages = BehaviorRelay<Int>(value: 1)
    
    private let groupSubject: BehaviorRelay<Group>
    let cathedraSubject: BehaviorRelay<Cathedra>
    
    init(group: Group, on cathedra: Cathedra) {
        groupSubject = BehaviorRelay(value: group)
        cathedraSubject = BehaviorRelay(value: cathedra)
        
        super.init()
    }
    
    func transform(input: Input) -> Output {
        return Output(
            groupName: groupSubject
                .map { $0.name }
                .asDriver(onErrorJustReturn: ""),
            cathedraName: cathedraSubject
                .map { $0.name }
                .asDriver(onErrorJustReturn: ""),
            semesterNumberText: groupSubject
                .map { String(format: "SEMESTERS_COUNT_TEXT".localized, $0.numberOfSemesters) }
                .asDriver(onErrorJustReturn: ""),
            studentsCountText: groupSubject
                .map { String(format: "STUDENTS_COUNT_TEXT".localized, $0.studentsCount) }
                .asDriver(onErrorJustReturn: "")
        )
    }
    
}

// MARK: - INPUTS/OUTPUTS
extension GroupDetailsViewModel {
    struct Input {
        
    }
    
    struct Output {
        let groupName: Driver<String>
        let cathedraName: Driver<String>
        let semesterNumberText: Driver<String>
        let studentsCountText: Driver<String>
    }
    
    struct Segue {
        static let editGroup = "editGroupSegue"
    }
}

// MARK: - HELPER FUNCTIONS
extension GroupDetailsViewModel {
    
}
