import UIKit
import RxSwift
import RxCocoa

class GroupCreateEditViewController: BaseTableViewController {
    
    @IBOutlet var groupNameTextField: UITextField!
    @IBOutlet var semesterNumberTextField: UITextField!
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var deleteButtonContainer: UIView!
    @IBOutlet var saveBarButtonItem: UIBarButtonItem!
    @IBOutlet var cancelBarButtonItem: UIBarButtonItem!
    
    @IBOutlet var cellNameLabels: [UILabel]!
    @IBOutlet var textFieldsLeadingConstraints: [NSLayoutConstraint]!
    
    var viewModel: GroupCreateEditViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        
        bind(output: viewModel.transform(input: GroupCreateEditViewModel.Input(
            groupNameChanged: groupNameTextField.rx.text,
            semesterNumberChanged: semesterNumberTextField.rx.text,
            saveTrigger: saveBarButtonItem.rx.tap,
            cancelTrigger: cancelBarButtonItem.rx.tap,
            deleteTrigger: deleteButton.rx.tap,
            viewDidDissapear: self.rx.viewDidDisappear
        )))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupTextFields()
    }
    
    private func bind(output: GroupCreateEditViewModel.Output) {
        self.rx.viewDidAppear
            .filter { _ in self.viewModel.groupToBeEditedSubject.value == nil }
            .bind(onNext: { _ in
                self.groupNameTextField.becomeFirstResponder()
            })
            .disposed(by: disposeBag)
        
        saveBarButtonItem.rx.tap
            .bind(onNext: {
                let loadingBarButtonItem = UIBarButtonItem()
                let loadingIndicator = UIActivityIndicatorView(style: .medium)
                loadingBarButtonItem.customView = loadingIndicator
                self.navigationItem.rightBarButtonItem = loadingBarButtonItem
                loadingIndicator.startAnimating()
            })
            .disposed(by: disposeBag)
        
        cancelBarButtonItem.rx.tap
            .bind(onNext: {
                self.navigationController?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
        
        output.groupName
            .drive(groupNameTextField.rx.text)
            .disposed(by: disposeBag)
        
        output.semesterNumber
            .drive(semesterNumberTextField.rx.text)
            .disposed(by: disposeBag)
        
        output.navItemTitle
            .drive(navigationItem.rx.title)
            .disposed(by: disposeBag)
        
        output.saveBarButtonItemEnabled
            .drive(saveBarButtonItem!.rx.isEnabled)
            .disposed(by: disposeBag)
        
        output.groupDidManipulate
            .drive(onNext: { _ in
                self.navigationItem.rightBarButtonItem = self.saveBarButtonItem
            })
            .disposed(by: disposeBag)
        output.groupDidManipulate
            .filter { $0 != nil }
            .drive(onNext: { _ in
                self.navigationController?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
        
        output.deleteButtonVisible
            .drive(onNext: toggleDeleteButton(_:))
            .disposed(by: disposeBag)
        
        viewModel.groupDeletedSubject
            .filter { $0 }
            .observeOn(MainScheduler.instance)
            .bind(onNext: { _ in
                self.navigationController?.dismiss(animated: true)
            })
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
        viewModel.groupDeletedSubject
            .observeOn(MainScheduler.instance)
            .bind(onNext: { _ in
                self.deleteButton.setTitle("DELETE".localized, for: .normal)
                self.deleteButton.subviews
                    .first(where: { $0.tag == 228 })?
                    .removeFromSuperview()
            })
            .disposed(by: disposeBag)
        viewModel.groupDeletedSubject
            .map { _ in true }
            .bind(to: deleteButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }
    
}

// MARK: - HELPER FUNCTIONS
extension GroupCreateEditViewController {
    private func setupNavigationBar() {
        navigationController?.navigationBar.addBlurEffect()
    }
    
    private func setupTextFields() {
        let constant = (
            cellNameLabels.map { cellNameLabel in
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
            tableView.tableFooterView = deleteButtonContainer
        } else {
            tableView.tableFooterView = UIView(frame: .zero)
        }
    }
    
    private func presentError(with message: String) {
        let alertController = UIAlertController(title: "ERROR_DURING_DELETING_GROUP_TITLE".localized, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK".localized, style: .default))
        present(alertController, animated: true)
    }
}
