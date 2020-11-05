import UIKit
import RxViewController

class FacultiesListViewController: TemporaryNavBarViewController {
    
    @IBOutlet var tableView: UITableView!
    
    private let viewModel = FacultiesListViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupNavigationBar()
        
        bind(output: viewModel.transform(input: FacultiesListViewModel.Input(
            viewDidAppear: self.rx.viewDidAppear,
            viewDidDisappear: self.rx.viewDidDisappear,
            cellDidSelect: tableView.rx.itemSelected
        )))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.contentInset.top = navigationBarHeight
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.contentInset.top = 0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier {
        case FacultiesListViewModel.Segue.showFaculty:
            guard let facultyDetailsViewController = segue.destination as? FacultyDetailsViewController else { return }
            facultyDetailsViewController.viewModel = FacultyDetailsViewModel(faculty: sender as! Faculty)
        case FacultiesListViewModel.Segue.createFaculty:
            guard let navController = segue.destination as? UINavigationController,
                let facultyCreateViewController = navController.topViewController as? FacultyCreateEditViewController else { return }
            facultyCreateViewController.viewModel = FacultyCreateEditViewModel(facultyToBeEdit: nil)
            
            facultyCreateViewController.viewModel
                .facultyManipulatedSubject
                .filter { $0 != nil }
                .map { $0! }
                .bind(onNext: { [unowned self] in
                    self.viewModel.facultyDidCreate(faculty: $0)
                })
                .disposed(by: disposeBag)
            navController.isModalInPresentation = true
        default:
            break
        }
    }
    
    private func bind(output: FacultiesListViewModel.Output) {
        tableView.rx.itemSelected
            .bind(onNext: { [unowned self] indexPath in
                self.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)
        
        output.facultyCellsData
            .drive(tableView.rx.items) { tableView, row, facultyCellData in
                if facultyCellData.cellType == .loadingCell {
                    self.viewModel.loadMoreFacultySubject.onNext(())
                }
                let cell = self.cell(for: facultyCellData)
                cell.separatorInset.left = facultyCellData.cellType == .loadingCell ? UIScreen.main.bounds.width : 16
                return cell
            }.disposed(by: disposeBag)
        
        output.facultyCellsData
            .map { $0.isEmpty ? "NO_FACULTIES".localized : nil }
            .drive(onNext: { [unowned self] in
                self.tableView.setEmptyTitle($0)
            })
            .disposed(by: disposeBag)
        
        output.facultySelected
            .drive(onNext: { [unowned self] in
                self.presentFaculty($0)
            })
            .disposed(by: disposeBag)
    }
    
}

extension FacultiesListViewController {
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createNewFaculty))
    }
    
    private func setupTableView() {
        tableView.register(UINib(nibName: "LoadingCell", bundle: nil), forCellReuseIdentifier: LoadingCell.identifier)
        tableView.register(UINib(nibName: "FacultyCell", bundle: nil), forCellReuseIdentifier: FacultyCell.identifier)
        tableView.tableFooterView = UIView(frame: .zero)
    }
    
    private func cell(for data: FacultyCellData) -> UITableViewCell {
        switch data.cellType {
        case .facultyCell:
            let facultyCell = tableView.dequeueReusableCell(withIdentifier: data.cellType.rawValue) as! FacultyCell
            facultyCell.reset(with: data.item!)
            return facultyCell
        case .loadingCell:
            let loadingCell = tableView.dequeueReusableCell(withIdentifier: data.cellType.rawValue) as! LoadingCell
            loadingCell.activityIndicator.startAnimating()
            return loadingCell
        default:
            return UITableViewCell()
        }
    }
    
    private func presentFaculty(_ faculty: Faculty) {
        performSegue(withIdentifier: FacultiesListViewModel.Segue.showFaculty, sender: faculty)
    }
    
    @objc private func createNewFaculty() {
        performSegue(withIdentifier: FacultiesListViewModel.Segue.createFaculty, sender: nil)
    }
}
