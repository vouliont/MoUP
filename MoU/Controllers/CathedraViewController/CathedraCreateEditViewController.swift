import UIKit
import RxSwift
import RxCocoa

class CathedraCreateEditViewController: BaseTableViewController {
    
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var cellsNameLabels: [UILabel]!
    @IBOutlet var textFieldsLeadingConstraints: [NSLayoutConstraint]!
    
    @IBOutlet var cathedraNameTextField: UITextField!
    @IBOutlet var foundedDateTextField: RestrictTextField!
    @IBOutlet var siteUrlTextField: UITextField!
    @IBOutlet var additionalInfoTextField: UITextField!
    
    @IBOutlet var saveBarButtonItem: UIBarButtonItem!
    @IBOutlet var cancelBarButtonItem: UIBarButtonItem!
    
    @IBOutlet var deleteButtonContainerView: UIView!
    @IBOutlet var deleteButton: UIButton!
    
    var viewModel: CathedraCreateEditViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupNavigationBar()
        
        bind(output: viewModel.transform(input: CathedraCreateEditViewModel.Input(
            saveTrigger: saveBarButtonItem.rx.tap,
            cancelTrigger: cancelBarButtonItem.rx.tap,
            deleteTrigger: deleteButton.rx.tap,
            cathedraNameChanged: cathedraNameTextField.rx.text,
            foundedDateChanged: foundedDateTextField.rx.text,
            siteUrlChanged: siteUrlTextField.rx.text,
            additionalInfoChanged: additionalInfoTextField.rx.text,
            datePickerValueChanged: datePicker.rx.date,
            foundedDateEditingDidBegin: foundedDateTextField.rx.controlEvent(.editingDidBegin),
            foundedDateEditingDidEnd: foundedDateTextField.rx.controlEvent(.editingDidEnd),
            viewDidDissapear: self.rx.viewDidDisappear
        )))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupTextFields()
    }
    
    private func bind(output: CathedraCreateEditViewModel.Output) {
        self.rx.viewDidAppear
            .filter { _ in self.viewModel.cathedraToBeEditedSubject.value == nil }
            .bind(onNext: { _ in
                self.cathedraNameTextField.becomeFirstResponder()
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
        
        output.navItemTitle
            .drive(navigationItem.rx.title)
            .disposed(by: disposeBag)
        
        output.saveBarButtonItemEnabled
            .drive(saveBarButtonItem!.rx.isEnabled)
            .disposed(by: disposeBag)
        
        output.cathedraName
            .drive(cathedraNameTextField.rx.text)
            .disposed(by: disposeBag)
        output.foundedDate
            .drive(foundedDateTextField.rx.text)
            .disposed(by: disposeBag)
        output.siteUrl
            .drive(siteUrlTextField.rx.text)
            .disposed(by: disposeBag)
        output.additionalInfo
            .drive(additionalInfoTextField.rx.text)
            .disposed(by: disposeBag)
        
        output.cathedraDidManipulate
            .drive(onNext: { _ in
                self.navigationItem.rightBarButtonItem = self.saveBarButtonItem
            })
            .disposed(by: disposeBag)
        output.cathedraDidManipulate
            .filter { $0 != nil }
            .drive(onNext: { _ in
                self.navigationController?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
        
        output.datePickerValue
            .drive(datePicker.rx.date)
            .disposed(by: disposeBag)
        
        output.deleteButtonVisible
            .drive(onNext: toggleDeleteButton(_:))
            .disposed(by: disposeBag)
        
        viewModel.cathedraDeletedSubject
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
        viewModel.cathedraDeletedSubject
            .observeOn(MainScheduler.instance)
            .bind(onNext: { _ in
                self.deleteButton.setTitle("DELETE".localized, for: .normal)
                self.deleteButton.subviews
                    .first(where: { $0.tag == 228 })?
                    .removeFromSuperview()
            })
            .disposed(by: disposeBag)
        viewModel.cathedraDeletedSubject
            .map { _ in true }
            .bind(to: deleteButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }
    
}

// MARK: - HELPER FUNCTIONS
extension CathedraCreateEditViewController {
    private func setupTableView() {
        foundedDateTextField.inputView = datePicker
    }
    
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
        
        foundedDateTextField.restrictedActions.append(contentsOf: [.copy, .paste, .cut])
    }
    
    private func setupDatePicker() {
        datePicker.minimumDate = viewModel.minimumDate
        datePicker.maximumDate = viewModel.maximumDate
    }
    
    private func toggleDeleteButton(_ visible: Bool) {
        if visible {
            tableView.tableFooterView = deleteButtonContainerView
        } else {
            tableView.tableFooterView = UIView(frame: .zero)
        }
    }
    
    private func presentError(with message: String) {
        let alertController = UIAlertController(title: "ERROR_DURING_DELETING_CATHEDRA_TITLE".localized, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK".localized, style: .default))
        present(alertController, animated: true)
    }
}
