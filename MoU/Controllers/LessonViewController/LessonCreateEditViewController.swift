import UIKit
import RxSwift
import RxCocoa

class LessonCreateEditViewController: BaseTableViewController {
    
    @IBOutlet var cellsNameLabels: [UILabel]!
    @IBOutlet var textFieldsLeadingConstraints: [NSLayoutConstraint]!
    
    @IBOutlet var lessonNameTextField: UITextField!
    @IBOutlet var professorCell: UITableViewCell!
    @IBOutlet var professorNameTextField: UITextField!
    
    @IBOutlet var saveBarButtonItem: UIBarButtonItem!
    @IBOutlet var cancelBarButtonItem: UIBarButtonItem!
    
    @IBOutlet var deleteButtonContainerView: UIView!
    @IBOutlet var deleteButton: UIButton!
    
    var viewModel: LessonCreateEditViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        
        bind(output: viewModel.transform(input: LessonCreateEditViewModel.Input(
            saveTrigger: saveBarButtonItem.rx.tap,
            deleteTrigger: deleteButton.rx.tap,
            lessonNameChanged: lessonNameTextField.rx.text,
            viewDidDissapear: self.rx.viewDidDisappear
        )))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupTextFields()
    }
    
    private func bind(output: LessonCreateEditViewModel.Output) {
        self.rx.viewDidAppear
            .filter { _ in self.viewModel.lessonToBeEditedSubject.value == nil }
            .bind(onNext: { _ in
                self.lessonNameTextField.becomeFirstResponder()
            })
            .disposed(by: disposeBag)
        
        cancelBarButtonItem.rx.tap
            .bind(onNext: {
                self.navigationController?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
        
        // todo: open teacher chooser view controller (need create one)
        tableView.rx.itemSelected
            .bind(onNext: {
                self.tableView.deselectRow(at: $0, animated: true)
            })
            .disposed(by: disposeBag)
        
        output.navItemTitle
            .drive(navigationItem.rx.title)
            .disposed(by: disposeBag)
        
        output.saveBarButtonItemEnabled
            .drive(saveBarButtonItem!.rx.isEnabled)
            .disposed(by: disposeBag)
        
        output.loadingBarIndicatorVisible
            .drive(onNext: { visible in
                if visible {
                    let loadingBarButtonItem = UIBarButtonItem()
                    let loadingIndicator = UIActivityIndicatorView(style: .medium)
                    loadingBarButtonItem.customView = loadingIndicator
                    self.navigationItem.rightBarButtonItem = loadingBarButtonItem
                    loadingIndicator.startAnimating()
                } else {
                    self.navigationItem.rightBarButtonItem = self.saveBarButtonItem
                }
            })
            .disposed(by: disposeBag)
        
        output.didManipulateSuccessfully
            .filter { $0 }
            .drive(onNext: { _ in
                self.navigationController?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
        
        output.deleteButtonVisible
            .drive(onNext: toggleDeleteButton(_:))
            .disposed(by: disposeBag)
        
        viewModel.errorSubject
            .filter { $0 is ApiError }
            .map { ($0 as! ApiError).localizedMessage }
            .bind(onNext: presentError(with:))
            .disposed(by: disposeBag)
        
        // Delete Button functionality
        deleteButton.rx.tap
            .bind(onNext: {
                self.deleteButton.setTitle(nil, for: .normal)
                let loadingIndicator = UIActivityIndicatorView(style: .medium)
                loadingIndicator.center = CGPoint(
                    x: self.deleteButton.bounds.width / 2,
                    y: self.deleteButton.bounds.height / 2
                )
                loadingIndicator.tag = 228
                loadingIndicator.color = .white
                self.deleteButton.addSubview(loadingIndicator)
                loadingIndicator.startAnimating()
            })
            .disposed(by: disposeBag)
        deleteButton.rx.tap
            .map { false }
            .bind(to: deleteButton.rx.isEnabled)
            .disposed(by: disposeBag)
        output.didManipulateSuccessfully
            .drive(onNext: { _ in
                self.deleteButton.setTitle("DELETE".localized, for: .normal)
                self.deleteButton.subviews
                    .first(where: { $0.tag == 228 })?
                    .removeFromSuperview()
            })
            .disposed(by: disposeBag)
        output.didManipulateSuccessfully
            .map { _ in true }
            .drive(deleteButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }
    
}

// MARK: - HELPER FUNCTIONS
extension LessonCreateEditViewController {
    private func setupNavigationBar() {
        navigationController?.navigationBar.addBlurEffect()
    }
    
    private func setupTextFields() {
        let constant = (
            cellsNameLabels.map { cellNameLabel in
                cellNameLabel.sizeToFit()
                return cellNameLabel.bounds.size.width
            } as [CGFloat]
            ).max()
        
        textFieldsLeadingConstraints.forEach { constraint in
            constraint.constant = (constant ?? constraint.constant) + 12
        }
    }
    
    private func toggleDeleteButton(_ visible: Bool) {
        if visible {
            tableView.tableFooterView = deleteButtonContainerView
        } else {
            tableView.tableFooterView = UIView(frame: .zero)
        }
    }
    
    private func presentError(with message: String) {
        let alertController = UIAlertController(title: "ERROR_DURING_DELETING_LESSON_TITLE".localized, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK".localized, style: .default))
        present(alertController, animated: true)
    }
}
