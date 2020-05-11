import UIKit
import RxSwift
import RxCocoa

class LoginViewController: KeyboardViewController {

    @IBOutlet var loginTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var logInButton: UIButton!
    
    private let viewModel = LoginViewModel()
    
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
        
        // todo: userDataLoaded bind
        
        output.errorHasOccured
            .drive(onNext: showError)
            .disposed(by: disposeBag)
        
        let textFields: [UITextField] = [loginTextField, passwordTextField]
        textFields.forEach { textField in
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
