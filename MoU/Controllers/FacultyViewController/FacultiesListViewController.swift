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
                .bind(onNext: viewModel.facultyDidCreate(faculty:))
                .disposed(by: disposeBag)
            navController.isModalInPresentation = true
        default:
            break
        }
    }
    
    private func bind(output: FacultiesListViewModel.Output) {
        tableView.rx.itemSelected
            .bind(onNext: { indexPath in
                self.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)
        
        output.facultyCellsData
            .drive(tableView.rx.items) { tableView, row, facultyCellData in
                if facultyCellData.cellIdentifier == .loadingCell {
                    self.viewModel.loadMoreFacultySubject.onNext(())
                }
                return self.cell(for: facultyCellData)
            }.disposed(by: disposeBag)
        
        output.facultySelected
            .drive(onNext: presentFaculty)
            .disposed(by: disposeBag)
    }
    
}

extension FacultiesListViewController {
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createNewFaculty))
    }
    
    private func setupTableView() {
        tableView.register(UINib(nibName: "LoadingCell", bundle: nil), forCellReuseIdentifier: "loadingCell")
        tableView.register(UINib(nibName: "FacultyCell", bundle: nil), forCellReuseIdentifier: FacultyCell.identifier)
    }
    
    private func cell(for data: FacultyCellData) -> UITableViewCell {
        switch data.cellIdentifier {
        case .facultyCell:
            let facultyCell = tableView.dequeueReusableCell(withIdentifier: data.cellIdentifier.rawValue) as! FacultyCell
            facultyCell.reset(with: data.faculty!)
            return facultyCell
        case .loadingCell:
            let loadingCell = tableView.dequeueReusableCell(withIdentifier: data.cellIdentifier.rawValue) as! LoadingCell
            loadingCell.activityIndicator.startAnimating()
            return loadingCell
        }
    }
    
    private func presentFaculty(_ faculty: Faculty) {
        performSegue(withIdentifier: FacultiesListViewModel.Segue.showFaculty, sender: faculty)
    }
    
    @objc private func createNewFaculty() {
        performSegue(withIdentifier: FacultiesListViewModel.Segue.createFaculty, sender: nil)
    }
}
