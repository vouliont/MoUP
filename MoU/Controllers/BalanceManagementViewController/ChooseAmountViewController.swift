import UIKit
import RxSwift
import RxCocoa

class ChooseAmountViewController: KeyboardViewController {
    
    @IBOutlet var rechargeButton: BaseButton!
    @IBOutlet var rechargeButtonBottomViewHeight: NSLayoutConstraint!
    @IBOutlet var rechargeButtonBottomView: UIView!
    @IBOutlet var amountTextField: UITextField!
    @IBOutlet var cancelBarButtonItem: UIBarButtonItem!
    
    private let shouldChangeCharacterSubject = PublishRelay<String>()
    
    private let viewModel = ChooseAmountViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        setupBottomPadding()
        toggleButtonBottomView(visible: true, animated: false)
        setupTextField()
        
        bind(output: viewModel.transform(input: ChooseAmountViewModel.Input(
            amountChanged: shouldChangeCharacterSubject.asObservable(),
            rechargeTriggered: rechargeButton.rx.controlEvent(.touchUpInside)
        )))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case ChooseAmountViewModel.Segue.liqpayWebView:
            guard let liqpayWebViewController = segue.destination as? LiqpayWebViewController else { return }
            liqpayWebViewController.viewModel = LiqpayWebViewModel(url: sender as! URL)
        default:
            break
        }
    }
    
    override func keyboardWillChange(notification: Notification) {
        super.keyboardWillChange(notification: notification)
        
        let bottomViewVisible = notification.name == UIResponder.keyboardWillHideNotification
        let duration = keyboardAnimationDuration(from: notification) ?? 0.2
        
        toggleButtonBottomView(visible: bottomViewVisible, animated: true, duration: duration)
    }
    
    private func bind(output: ChooseAmountViewModel.Output) {
        output.loadingBarIndicatorVisible
            .drive(onNext: { visible in
                if visible {
                    let loadingBarButtonItem = UIBarButtonItem()
                    let loadingIndicator = UIActivityIndicatorView(style: .medium)
                    loadingBarButtonItem.customView = loadingIndicator
                    self.navigationItem.rightBarButtonItem = loadingBarButtonItem
                    loadingIndicator.startAnimating()
                } else {
                    self.navigationItem.rightBarButtonItem = nil
                }
            })
            .disposed(by: disposeBag)
        
        output.amount
            .drive(amountTextField.rx.text)
            .disposed(by: disposeBag)
        
        output.rechargeButtonEnabled
            .drive(rechargeButton.rx.isEnabled)
            .disposed(by: disposeBag)
        output.rechargeButtonEnabled
            .drive(onNext: { isEnabled in
                self.rechargeButtonBottomView.backgroundColor = isEnabled ? self.rechargeButton.backgroundColorDefault : self.rechargeButton.backgroundColorDisabled
            })
            .disposed(by: disposeBag)
        
        output.liqpayUrlLoaded
            .drive(onNext: { url in
                self.performSegue(withIdentifier: ChooseAmountViewModel.Segue.liqpayWebView, sender: url)
            })
            .disposed(by: disposeBag)
        
        cancelBarButtonItem.rx.tap
            .bind(onNext: {
                self.navigationController?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
        
        self.rx.viewDidAppear
            .bind(onNext: { _ in
                self.amountTextField.becomeFirstResponder()
            })
            .disposed(by: disposeBag)
        
        rechargeButton.rx.tap
            .bind(onNext: {
                self.amountTextField.resignFirstResponder()
            })
            .disposed(by: disposeBag)
    }
    
}

// MARK: - HELPER FUNCTIONS
extension ChooseAmountViewController {
    private func setupNavigationBar() {
        navigationController?.navigationBar.addBlurEffect()
    }
    
    private func setupBottomPadding() {
        mainViewBottomPadding.constant = windowSafeAreaInsets?.bottom ?? 0
        defaultBottomPadding = windowSafeAreaInsets?.bottom ?? 0
    }
    
    private func toggleButtonBottomView(visible: Bool, animated: Bool, duration: TimeInterval = 0.2) {
        let viewHeight = visible ? (windowSafeAreaInsets?.bottom ?? 0) : 0
        rechargeButtonBottomViewHeight.constant = viewHeight
        UIView.animate(withDuration: animated ? duration : 0) {
            self.rechargeButtonBottomView.layoutIfNeeded()
        }
    }
    
    private func setupTextField() {
        amountTextField.delegate = self
    }
}

extension ChooseAmountViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        shouldChangeCharacterSubject.accept(string)
        return false
    }
}
