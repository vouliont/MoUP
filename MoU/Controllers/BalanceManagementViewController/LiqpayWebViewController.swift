import UIKit
import WebKit

class LiqpayWebViewController: BaseViewController {
    
    @IBOutlet var webView: WKWebView!
    @IBOutlet var doneBarButtonItem: UIBarButtonItem!
    
    var viewModel: LiqpayWebViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        bind(output: viewModel.transform(input: LiqpayWebViewModel.Input()))
    }
    
    private func bind(output: LiqpayWebViewModel.Output) {
        doneBarButtonItem.rx.tap
            .bind(onNext: {
                App.shared.updateUser(with: User.UpdatedPart.payments)
                self.navigationController?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
        
        output.url
            .drive(onNext: { url in
                self.webView.load(URLRequest(url: url))
            })
            .disposed(by: disposeBag)
    }
    
}
