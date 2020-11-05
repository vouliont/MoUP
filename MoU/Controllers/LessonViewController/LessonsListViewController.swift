import UIKit
import RxSwift
import RxCocoa

class LessonsListViewController: TemporaryNavBarViewController {
    
    @IBOutlet var tableView: UITableView!
    
    private let viewModel = LessonsListViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupNavigationBar()
        
        bind(output: viewModel.transform(input: LessonsListViewModel.Input(
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
//        case LessonsListViewModel.Segue.showLesson:
//            guard let lessonDetailsViewController = segue.destination as? FacultyDetailsViewController else { return }
//            facultyDetailsViewController.viewModel = FacultyDetailsViewModel(faculty: sender as! Faculty)
        case LessonsListViewModel.Segue.createLesson:
            guard let navController = segue.destination as? UINavigationController,
                let lessonCreateViewController = navController.topViewController as? LessonCreateEditViewController else { return }
            let lessonManipulatedListener = PublishRelay<Lesson>()
            lessonManipulatedListener
                .bind(onNext: viewModel.lessonDidCreate)
                .disposed(by: disposeBag)
            lessonCreateViewController.viewModel = LessonCreateEditViewModel(lessonToBeEdit: nil, lessonManipulatedListener: lessonManipulatedListener)

            navController.isModalInPresentation = true
        default:
            break
        }
    }

    private func bind(output: LessonsListViewModel.Output) {
        tableView.rx.itemSelected
            .bind(onNext: { indexPath in
                self.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)
        
        output.lessonCellsData
            .drive(tableView.rx.items) { tableView, row, lessonCellData in
                if lessonCellData.cellType == .loadingCell {
                    self.viewModel.loadMoreLessonSubject.onNext(())
                }
                let cell = self.cell(for: lessonCellData)
                cell.separatorInset.left = lessonCellData.cellType == .loadingCell ? UIScreen.main.bounds.width : 16
                return cell
            }.disposed(by: disposeBag)
        
        output.lessonCellsData
            .map { $0.isEmpty ? "NO_LESSONS".localized : nil }
            .drive(onNext: tableView.setEmptyTitle(_:))
            .disposed(by: disposeBag)
        
        output.lessonSelected
            .drive(onNext: presentLesson)
            .disposed(by: disposeBag)
    }
    
}

// MARK: - HELPER FUNCTIONS
extension LessonsListViewController {
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createNewLesson))
    }
    
    private func setupTableView() {
        tableView.register(UINib(nibName: "LoadingCell", bundle: nil), forCellReuseIdentifier: LoadingCell.identifier)
        tableView.register(UINib(nibName: "LessonCell", bundle: nil), forCellReuseIdentifier: LessonCell.identifier)
        tableView.tableFooterView = UIView(frame: .zero)
    }
    
    private func cell(for data: LessonCellData) -> UITableViewCell {
        switch data.cellType {
        case .lessonCell:
            let lessonCell = tableView.dequeueReusableCell(withIdentifier: data.cellType.rawValue) as! LessonCell
            lessonCell.reset(with: data.item!)
            return lessonCell
        case .loadingCell:
            let loadingCell = tableView.dequeueReusableCell(withIdentifier: data.cellType.rawValue) as! LoadingCell
            loadingCell.activityIndicator.startAnimating()
            return loadingCell
        default:
            return UITableViewCell()
        }
    }
    
    private func presentLesson(_ lesson: Lesson) {
        performSegue(withIdentifier: LessonsListViewModel.Segue.showLesson, sender: lesson)
    }
    
    @objc private func createNewLesson() {
        performSegue(withIdentifier: LessonsListViewModel.Segue.createLesson, sender: nil)
    }
}

