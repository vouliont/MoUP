import UIKit
import RxSwift
import RxViewController

class FacultyDetailsViewController: BaseViewController {
    
    @IBOutlet var facultyNameLabel: UILabel!
    @IBOutlet var foundedDateLabel: UILabel!
    @IBOutlet var linkButton: UIButton!
    @IBOutlet var additionalInfoLabel: UILabel!
    @IBOutlet var cathedrasTableView: UITableView!
    @IBOutlet var tableHeaderView: UIVisualEffectView!
    
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
                .bind(onNext: viewModel.facultyDidEdit(faculty:))
                .disposed(by: disposeBag)
            facultyEditViewController.viewModel
                .facultyDeletedSubject
                .filter { $0 }
                .map { _ in () }
                .observeOn(MainScheduler.instance)
                .bind(onNext: facultyDeletionSuccess)
                .disposed(by: disposeBag)
            navController.isModalInPresentation = true
        default:
            break
        }
    }
    
    private func bind(output: FacultyDetailsViewModel.Output) {
        linkButton.rx.controlEvent(.touchUpInside)
            .bind(onNext: openLink)
            .disposed(by: disposeBag)
        
        output.facultyName
            .drive(facultyNameLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.formattedFoundedDate
            .drive(foundedDateLabel.rx.text)
            .disposed(by: disposeBag)
        output.dateVisible
            .drive(onNext: { visible in
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
            .drive(onNext: { visible in
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
            .drive(onNext: { visible in
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
                if cathedraCellData.cellIdentifier == .loadingCell {
                    self.viewModel.loadMoreCathedrasSubject.onNext(())
                }
                return self.cell(for: cathedraCellData)
            }.disposed(by: disposeBag)
    }
    
}

extension FacultyDetailsViewController {
    private func setupTableView() {
        cathedrasTableView.tableHeaderView = tableHeaderView
        cathedrasTableView.register(UINib(nibName: "CathedraCell", bundle: nil), forCellReuseIdentifier: "cathedraCell")
        cathedrasTableView.register(UINib(nibName: "LoadingCell", bundle: nil), forCellReuseIdentifier: "loadingCell")
    }
    
    private func setupNavigationBar() {
        navigationItem.title = "Faculty"
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
        switch data.cellIdentifier {
        case .loadingCell:
            let cell = cathedrasTableView.dequeueReusableCell(withIdentifier: data.cellIdentifier.rawValue) as! LoadingCell
            cell.activityIndicator.startAnimating()
            return cell
        case .cathedraCell:
            let cell = cathedrasTableView.dequeueReusableCell(withIdentifier: data.cellIdentifier.rawValue) as! CathedraCell
            cell.reset(with: data.cathedra!)
            return cell
        }
    }
}
