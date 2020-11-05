import UIKit
import RxSwift
import RxCocoa
import RxViewController

class LoginViewController: KeyboardViewController {

    @IBOutlet var loginTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var logInButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    private let viewModel = LoginViewModel()
    
    private var lastActiveTextField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bind(output: viewModel.transform(input: LoginViewModel.Input(
            loginTextFieldTextChanged: loginTextField.rx.text,
            passwordTextFieldTextChanged: passwordTextField.rx.text,
            logInButtonTriggered: logInButton.rx.controlEvent(.touchUpInside)
        )))
    }
    
    private func bind(output: LoginViewModel.Output) {
        output.logInButtonEnable
            .drive(logInButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        viewModel.loading
            .map { !$0 }
            .drive(activityIndicator.rx.isHidden)
            .disposed(by: disposeBag)
        viewModel.loading
            .map { !$0 }
            .drive(loginTextField.rx.isUserInteractionEnabled)
            .disposed(by: disposeBag)
        viewModel.loading
            .map { !$0 }
            .drive(passwordTextField.rx.isUserInteractionEnabled)
            .disposed(by: disposeBag)
        
        self.rx.viewDidAppear
            .bind(onNext: { [unowned self] _ in
                self.loginTextField.becomeFirstResponder()
            })
            .disposed(by: disposeBag)
        
        output.errorHasOccured
            .drive(onNext: { [unowned self] in
                self.showError($0)
            })
            .disposed(by: disposeBag)
        
        logInButton.rx.controlEvent(.touchUpInside)
            .bind(onNext: { [unowned self] in self.lastActiveTextField?.resignFirstResponder() })
            .disposed(by: disposeBag)
        
        let textFields: [UITextField] = [loginTextField, passwordTextField]
        textFields.forEach { textField in
            textField.rx.controlEvent(.editingDidBegin)
                .bind(onNext: { [unowned self] in self.lastActiveTextField = textField })
                .disposed(by: disposeBag)
            textField.rx.controlEvent(.editingDidEnd)
                .bind(onNext: { textField.layoutIfNeeded() })
                .disposed(by: disposeBag)
            textField.rx.controlEvent(.editingDidEndOnExit)
                .bind(onNext: { textField.resignFirstResponder() })
                .disposed(by: disposeBag)
        }
    }
    
}

extension LoginViewController {
    private func showError(_ localizedErrorDescription: String) {
        let alertController = UIAlertController(title: "ERROR_HAS_OCCURED_TITLE".localized, message: localizedErrorDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK".localized, style: .default))
        present(alertController, animated: true)
    }
}
