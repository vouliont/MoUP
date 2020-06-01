import UIKit
import RxSwift

class CathedraDetailsViewController: BaseViewController {
    
    @IBOutlet var cathedraNameLabel: UILabel!
    @IBOutlet var foundedDateLabel: UILabel!
    @IBOutlet var linkButton: UIButton!
    @IBOutlet var additionalInfoLabel: UILabel!
    @IBOutlet var groupsTableView: UITableView!
    @IBOutlet var tableTitleViewHeight: NSLayoutConstraint!
    
    private var dateLabelConstraints = [NSLayoutConstraint]()
    private var additionalInfoLabelConstraints = [NSLayoutConstraint]()
    private var linkButtonConstraints = [NSLayoutConstraint]()
    
    var viewModel: CathedraDetailsViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupNavigationBar()
        
        bind(output: viewModel.translate(input: CathedraDetailsViewModel.Input(
            viewDidAppear: self.rx.viewDidAppear,
            viewDidDisappear: self.rx.viewDidDisappear
        )))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier {
        case CathedraDetailsViewModel.Segue.editCathedra:
            guard let navController = segue.destination as? UINavigationController,
                let cathedraEditViewController = navController.topViewController as? CathedraCreateEditViewController else { return }
            cathedraEditViewController.viewModel = CathedraCreateEditViewModel(cathedraToBeEdited: sender as? Cathedra, on: viewModel.facultySubject.value)
            cathedraEditViewController.viewModel
                .cathedraManipulatedSubject
                .filter { $0 != nil }
                .map { $0! }
                .bind(onNext: viewModel.cathedraDidEdit(cathedra:))
                .disposed(by: disposeBag)
            cathedraEditViewController.viewModel
                .cathedraDeletedSubject
                .filter { $0 }
                .map { _ in () }
                .observeOn(MainScheduler.instance)
                .bind(onNext: cathedraDeletionSuccess)
                .disposed(by: disposeBag)
            navController.isModalInPresentation = true
//        case CathedraDetailsViewModel.Segue.groupDetails:
//            guard let cathedraDetailsViewController = segue.destination as? CathedraDetailsViewController else { return }
//            cathedraDetailsViewController.viewModel = CathedraDetailsViewModel(cathedra: sender as! Cathedra)
//        case CathedraDetailsViewModel.Segue.createGroup:
//            guard let navController = segue.destination as? UINavigationController,
//                let cathedraCreateViewController = navController.topViewController as? CathedraCreateEditViewController else { return }
//            cathedraCreateViewController.viewModel = CathedraCreateEditViewModel(cathedraToBeEdited: nil, on: viewModel.facultySubject.value)
//
//            cathedraCreateViewController.viewModel
//                .cathedraManipulatedSubject
//                .filter { $0 != nil }
//                .map { $0! }
//                .bind(onNext: viewModel.cathedraDidCreate(cathedra:))
//                .disposed(by: disposeBag)
//            navController.isModalInPresentation = true
        default:
            break
        }
    }
    
    private func bind(output: CathedraDetailsViewModel.Output) {
        linkButton.rx.tap
            .bind(onNext: {
                guard let link = self.viewModel.cathedraSubject.value.siteUrl else { return }
                guard let url = URL(string: link) else { return }
                
                UIApplication.shared.open(url)
            })
            .disposed(by: disposeBag)
        
        output.cathedraName
            .drive(cathedraNameLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.formattedFoundedDate
            .drive(foundedDateLabel.rx.text)
            .disposed(by: disposeBag)
        output.dateVisible
            .drive(onNext: { visible in
                if visible {
                    self.foundedDateLabel.showWithConstraints(self.dateLabelConstraints)
                    self.dateLabelConstraints.removeAll()
                } else {
                    self.dateLabelConstraints.append(contentsOf: self.foundedDateLabel.hideWithConstraints())
                }
            })
            .disposed(by: disposeBag)
        
        output.linkVisible
            .drive(onNext: { visible in
                if visible {
                    self.linkButton.showWithConstraints(self.linkButtonConstraints)
                    self.linkButtonConstraints.removeAll()
                } else {
                    self.linkButtonConstraints.append(contentsOf: self.linkButton.hideWithConstraints())
                }
            })
            .disposed(by: disposeBag)
        
        output.additionalInfo
            .drive(additionalInfoLabel.rx.text)
            .disposed(by: disposeBag)
        output.additionalInfoVisible
            .drive(onNext: { visible in
                if visible {
                    self.additionalInfoLabel.showWithConstraints(self.additionalInfoLabelConstraints)
                    self.additionalInfoLabelConstraints.removeAll()
                } else {
                    self.additionalInfoLabelConstraints.append(contentsOf: self.additionalInfoLabel.hideWithConstraints())
                }
            })
            .disposed(by: disposeBag)
        
        output.groupCellsData
            .drive(groupsTableView.rx.items) { tableView, row, groupCellData in
                if groupCellData.cellType == .loadingCell {
                    self.viewModel.loadMoreGroupsSubject.onNext(())
                }
                let cell = self.cell(for: groupCellData)
                cell.separatorInset.left = groupCellData.cellType == .loadingCell ? UIScreen.main.bounds.width : 16
                return cell
            }.disposed(by: disposeBag)
        
        output.groupCellsData
            .map { $0.isEmpty ? "NO_GROUPS".localized : nil }
            .drive(onNext: groupsTableView.setEmptyTitle(_:))
            .disposed(by: disposeBag)
        
        groupsTableView.rx.itemSelected
            .bind(onNext: { indexPath in
                self.groupsTableView.deselectRow(at: indexPath, animated: true)
                let group = self.viewModel.group(for: indexPath)
                self.performSegue(withIdentifier: CathedraDetailsViewModel.Segue.groupDetails, sender: group)
            })
            .disposed(by: disposeBag)
    }
    
}

extension CathedraDetailsViewController {
    private func setupTableView() {
        groupsTableView.contentInset.top = tableTitleViewHeight.constant
        groupsTableView.tableFooterView = UIView(frame: .zero)
        
        groupsTableView.register(UINib(nibName: "GroupCell", bundle: nil), forCellReuseIdentifier: GroupCell.identifier)
        groupsTableView.register(UINib(nibName: "LoadingCell", bundle: nil), forCellReuseIdentifier: LoadingCell.identifier)
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editCathedra))
    }
    
    @objc private func editCathedra() {
        performSegue(withIdentifier: CathedraDetailsViewModel.Segue.editCathedra, sender: viewModel.cathedraSubject.value)
    }
    
    private func cathedraDeletionSuccess() {
        navigationController?.popViewController(animated: true)
    }
    
    private func cell(for data: GroupCellData) -> UITableViewCell {
        switch data.cellType {
        case .loadingCell:
            let cell = groupsTableView.dequeueReusableCell(withIdentifier: data.cellType.rawValue) as! LoadingCell
            cell.activityIndicator.startAnimating()
            return cell
        case .groupCell:
            let cell = groupsTableView.dequeueReusableCell(withIdentifier: data.cellType.rawValue) as! GroupCell
            cell.reset(with: data.item!)
            return cell
        default:
            return UITableViewCell()
        }
    }
}
