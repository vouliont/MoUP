import UIKit
import RxSwift

class CathedraDetailsViewController: BaseViewController {
    
    @IBOutlet var cathedraNameLabel: UILabel!
    @IBOutlet var facultyNameLabel: UILabel!
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
        
        bind(output: viewModel.transform(input: CathedraDetailsViewModel.Input(
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
                .bind(onNext: { [unowned self] in
                    self.viewModel.cathedraDidEdit(cathedra: $0)
                })
                .disposed(by: disposeBag)
            cathedraEditViewController.viewModel
                .cathedraDeletedSubject
                .filter { $0 }
                .map { _ in () }
                .observeOn(MainScheduler.instance)
                .bind(onNext: { [unowned self] in
                    self.cathedraDeletionSuccess()
                })
                .disposed(by: disposeBag)
            navController.isModalInPresentation = true
        case CathedraDetailsViewModel.Segue.groupDetails:
            guard let groupDetailsViewController = segue.destination as? GroupDetailsViewController else { return }
            groupDetailsViewController.viewModel = GroupDetailsViewModel(group: sender as! Group, on: viewModel.cathedraSubject.value)
        case CathedraDetailsViewModel.Segue.createGroup:
            guard let navController = segue.destination as? UINavigationController,
                let groupCreateViewController = navController.topViewController as? GroupCreateEditViewController else { return }
            groupCreateViewController.viewModel = GroupCreateEditViewModel(groupToBeEdited: nil, on: viewModel.cathedraSubject.value)

            groupCreateViewController.viewModel
                .groupManipulatedSubject
                .filter { $0 != nil }
                .map { $0! }
                .bind(onNext: { [unowned self] in
                    self.viewModel.groupDidCreate(group: $0)
                })
                .disposed(by: disposeBag)
            navController.isModalInPresentation = true
        default:
            break
        }
    }
    
    private func bind(output: CathedraDetailsViewModel.Output) {
        linkButton.rx.tap
            .bind(onNext: { [unowned self] in
                guard let link = self.viewModel.cathedraSubject.value.siteUrl else { return }
                guard let url = URL(string: link) else { return }
                
                UIApplication.shared.open(url)
            })
            .disposed(by: disposeBag)
        
        output.cathedraName
            .drive(cathedraNameLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.facultyName
            .drive(facultyNameLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.formattedFoundedDate
            .drive(foundedDateLabel.rx.text)
            .disposed(by: disposeBag)
        output.dateVisible
            .drive(onNext: { [unowned self] visible in
                if visible {
                    self.foundedDateLabel.showWithConstraints(self.dateLabelConstraints)
                    self.dateLabelConstraints.removeAll()
                } else {
                    self.dateLabelConstraints.append(contentsOf: self.foundedDateLabel.hideWithConstraints())
                }
            })
            .disposed(by: disposeBag)
        
        output.linkVisible
            .drive(onNext: { [unowned self] visible in
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
            .drive(onNext: { [unowned self] visible in
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
            .drive(onNext: { [unowned self] in
                self.groupsTableView.setEmptyTitle($0)
            })
            .disposed(by: disposeBag)
        
        groupsTableView.rx.itemSelected
            .bind(onNext: { [unowned self] indexPath in
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
