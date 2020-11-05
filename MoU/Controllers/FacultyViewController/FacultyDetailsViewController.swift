import UIKit
import RxSwift
import RxViewController

class FacultyDetailsViewController: BaseViewController {
    
    @IBOutlet var facultyNameLabel: UILabel!
    @IBOutlet var foundedDateLabel: UILabel!
    @IBOutlet var linkButton: UIButton!
    @IBOutlet var additionalInfoLabel: UILabel!
    @IBOutlet var cathedrasTableView: UITableView!
    @IBOutlet var tableTitleViewHeight: NSLayoutConstraint!
    @IBOutlet var createNewCathedraButton: UIButton!
    
    private var foundedDateLayoutConstraints = [NSLayoutConstraint]()
    private var linkButtonLayoutConstraints = [NSLayoutConstraint]()
    private var additionalInfoLayoutConstraints = [NSLayoutConstraint]()
    
    var viewModel: FacultyDetailsViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupNavigationBar()
        
        bind(output: viewModel.transform(input: FacultyDetailsViewModel.Input(
            viewDidAppear: self.rx.viewDidAppear,
            viewDidDisappear: self.rx.viewDidDisappear
        )))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier {
        case FacultyDetailsViewModel.Segue.editFaculty:
            guard let navController = segue.destination as? UINavigationController,
                let facultyEditViewController = navController.topViewController as? FacultyCreateEditViewController else { return }
            facultyEditViewController.viewModel = FacultyCreateEditViewModel(facultyToBeEdit: sender as? Faculty)
            facultyEditViewController.viewModel
                .facultyManipulatedSubject
                .filter { $0 != nil }
                .map { $0! }
                .bind(onNext: { [unowned self] in
                    self.viewModel.facultyDidEdit(faculty: $0)
                })
                .disposed(by: disposeBag)
            facultyEditViewController.viewModel
                .facultyDeletedSubject
                .filter { $0 }
                .map { _ in () }
                .observeOn(MainScheduler.instance)
                .bind(onNext: { [unowned self] in
                    self.facultyDeletionSuccess()
                })
                .disposed(by: disposeBag)
            navController.isModalInPresentation = true
        case FacultyDetailsViewModel.Segue.cathedraDetails:
            guard let cathedraDetailsViewController = segue.destination as? CathedraDetailsViewController else { return }
            cathedraDetailsViewController.viewModel = CathedraDetailsViewModel(cathedra: sender as! Cathedra, on: viewModel.facultySubject.value)
        case FacultiesListViewModel.Segue.createCathedra:
            guard let navController = segue.destination as? UINavigationController,
                let cathedraCreateViewController = navController.topViewController as? CathedraCreateEditViewController else { return }
            cathedraCreateViewController.viewModel = CathedraCreateEditViewModel(cathedraToBeEdited: nil, on: viewModel.facultySubject.value)
            
            cathedraCreateViewController.viewModel
                .cathedraManipulatedSubject
                .filter { $0 != nil }
                .map { $0! }
                .bind(onNext: { [unowned self] in
                    self.viewModel.cathedraDidCreate(cathedra: $0)
                })
                .disposed(by: disposeBag)
            navController.isModalInPresentation = true
        default:
            break
        }
    }
    
    private func bind(output: FacultyDetailsViewModel.Output) {
        linkButton.rx.controlEvent(.touchUpInside)
            .bind(onNext: { [unowned self] in
                self.openLink()
            })
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
                    self.foundedDateLabel.showWithConstraints(self.foundedDateLayoutConstraints)
                    self.foundedDateLayoutConstraints.removeAll()
                } else {
                    self.foundedDateLayoutConstraints.append(contentsOf: self.foundedDateLabel.hideWithConstraints())
                }
                self.foundedDateLabel.layoutIfNeeded()
            })
            .disposed(by: disposeBag)
        
        output.linkVisible
            .drive(onNext: { [unowned self] visible in
                if visible {
                    self.linkButton.showWithConstraints(self.linkButtonLayoutConstraints)
                    self.linkButtonLayoutConstraints.removeAll()
                } else {
                    self.linkButtonLayoutConstraints.append(contentsOf: self.linkButton.hideWithConstraints())
                }
                self.linkButton.layoutIfNeeded()
            })
            .disposed(by: disposeBag)
        
        output.additionalInfo
            .drive(additionalInfoLabel.rx.text)
            .disposed(by: disposeBag)
        output.additionalInfoVisible
            .drive(onNext: { [unowned self] visible in
                if visible {
                    self.additionalInfoLabel.showWithConstraints(self.additionalInfoLayoutConstraints)
                    self.additionalInfoLayoutConstraints.removeAll()
                } else {
                    self.additionalInfoLayoutConstraints.append(contentsOf: self.additionalInfoLabel.hideWithConstraints())
                }
                self.additionalInfoLabel.layoutIfNeeded()
            })
            .disposed(by: disposeBag)
        
        output.cathedraCellsData
            .drive(cathedrasTableView.rx.items) { tableView, row, cathedraCellData in
                if cathedraCellData.cellType == .loadingCell {
                    self.viewModel.loadMoreCathedrasSubject.onNext(())
                }
                let cell = self.cell(for: cathedraCellData)
                cell.separatorInset.left = cathedraCellData.cellType == .loadingCell ? UIScreen.main.bounds.width : 16
                return cell
            }.disposed(by: disposeBag)
        
        output.cathedraCellsData
            .map { $0.isEmpty ? "NO_CATHEDRAS".localized : nil }
            .drive(onNext: { [unowned self] in
                self.cathedrasTableView.setEmptyTitle($0)
            })
            .disposed(by: disposeBag)
        
        cathedrasTableView.rx.itemSelected
            .bind(onNext: { [unowned self] indexPath in
                self.cathedrasTableView.deselectRow(at: indexPath, animated: true)
                let cathedra = self.viewModel.cathedra(for: indexPath)
                self.performSegue(withIdentifier: FacultyDetailsViewModel.Segue.cathedraDetails, sender: cathedra)
            })
            .disposed(by: disposeBag)
    }
    
}

extension FacultyDetailsViewController {
    private func setupTableView() {
        cathedrasTableView.contentInset.top = tableTitleViewHeight.constant
        cathedrasTableView.tableFooterView = UIView(frame: .zero)
        cathedrasTableView.register(UINib(nibName: "CathedraCell", bundle: nil), forCellReuseIdentifier: CathedraCell.identifier)
        cathedrasTableView.register(UINib(nibName: "LoadingCell", bundle: nil), forCellReuseIdentifier: LoadingCell.identifier)
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editFaculty))
    }
    
    @objc private func editFaculty() {
        performSegue(withIdentifier: FacultyDetailsViewModel.Segue.editFaculty, sender: viewModel.facultySubject.value)
    }
    
    private func openLink() {
        guard let link = viewModel.facultySubject.value.siteUrl else { return }
        guard let url = URL(string: link) else { return }
        
        UIApplication.shared.open(url)
    }
    
    private func facultyDeletionSuccess() {
        navigationController?.popViewController(animated: true)
    }
    
    private func cell(for data: CathedraCellData) -> UITableViewCell {
        switch data.cellType {
        case .loadingCell:
            let cell = cathedrasTableView.dequeueReusableCell(withIdentifier: data.cellType.rawValue) as! LoadingCell
            cell.activityIndicator.startAnimating()
            return cell
        case .cathedraCell:
            let cell = cathedrasTableView.dequeueReusableCell(withIdentifier: data.cellType.rawValue) as! CathedraCell
            cell.reset(with: data.item!)
            return cell
        default:
            return UITableViewCell()
        }
    }
}
