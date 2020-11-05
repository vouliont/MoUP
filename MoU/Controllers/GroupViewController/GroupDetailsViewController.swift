import UIKit
import RxSwift
import RxCocoa

class GroupDetailsViewController: BaseViewController {
    
    @IBOutlet var groupNameLabel: UILabel!
    @IBOutlet var cathedraNameLabel: UILabel!
    @IBOutlet var semesterNumberLabel: UILabel!
    @IBOutlet var studentsCountLabel: UILabel!
    @IBOutlet var tableTitleViewHeight: NSLayoutConstraint!
    @IBOutlet var lessonsTableView: UITableView!
    
    var viewModel: GroupDetailsViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        
        bind(output: viewModel.transform(input: GroupDetailsViewModel.Input()))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier {
        case GroupDetailsViewModel.Segue.editGroup:
            guard let navController = segue.destination as? UINavigationController,
                let groupEditViewController = navController.topViewController as? GroupCreateEditViewController else { return }
            groupEditViewController.viewModel = GroupCreateEditViewModel(groupToBeEdited: sender as? Group, on: viewModel.cathedraSubject.value)
//            groupEditViewController.viewModel
//                .groupManipulatedSubject
//                .filter { $0 != nil }
//                .map { $0! }
//                .bind(onNext: viewModel.groupDidEdit(group:))
//                .disposed(by: disposeBag)
//            groupEditViewController.viewModel
//                .groupDeletedSubject
//                .filter { $0 }
//                .map { _ in () }
//                .observeOn(MainScheduler.instance)
//                .bind(onNext: groupDeletionSuccess)
//                .disposed(by: disposeBag)
            navController.isModalInPresentation = true
        default:
            break
        }
    }
    
    private func bind(output: GroupDetailsViewModel.Output) {
        output.groupName
            .drive(groupNameLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.cathedraName
            .drive(cathedraNameLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.semesterNumberText
            .drive(semesterNumberLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.studentsCountText
            .drive(studentsCountLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
}

// MARK: - HELPER FUNCTIONS
extension GroupDetailsViewController {
    private func setupTableView() {
        lessonsTableView.contentInset.top = tableTitleViewHeight.constant
        lessonsTableView.tableFooterView = UIView(frame: .zero)
    }
}
