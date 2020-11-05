import UIKit

class HomeViewController: BaseViewController {
    
    @IBOutlet var topView: UIView!
    @IBOutlet var photoImageView: UIImageView!
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var logOutButton: UIButton!
    
    private let viewModel = HomeViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        
        setupNavigationBar()
        setupTableView()
        
        bind(output: viewModel.transform(input: HomeViewModel.Input(
            cellSelected: tableView.rx.itemSelected,
            logOutButtonTriggered: logOutButton.rx.controlEvent(.touchUpInside),
            viewDidAppear: self.rx.viewDidAppear
        )))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        topView.addBlurEffect(withStatusBar: true)
        tableView.contentInset.top = topView.bounds.height
        
        setupExitButton()
    }
    
    private func bind(output: HomeViewModel.Output) {
        output.userName
            .drive(userNameLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.email
            .drive(emailLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.userPhoto
            .map { $0 == nil ? UIImage(named: "emptyPhoto") : UIImage(data: $0!) }
            .drive(photoImageView.rx.image)
            .disposed(by: disposeBag)
        
        output.managementLinks
            .drive(tableView.rx.items) { tableView, row, homeCellData in
                let cell = tableView.dequeueReusableCell(withIdentifier: "baseCell")!
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = homeCellData.localizedTitle
                return cell
            }.disposed(by: disposeBag)
        
        output.needPerformSegue
            .drive(onNext: { [unowned self] in
                self.performSegue(withIdentifier: $0, sender: nil)
            })
            .disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .bind { indexPath in
                self.tableView.deselectRow(at: indexPath, animated: true)
            }.disposed(by: disposeBag)
    }
    
}

extension HomeViewController {
    private func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "baseCell")
        tableView.contentInset = UIEdgeInsets(top: 2, left: .zero, bottom: 2, right: .zero)
        tableView.tableFooterView = UIView(frame: .zero)
    }
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.addBlurEffect(withStatusBar: true)
    }
    
    private func setupExitButton() {
        guard let safeAreaBottomInset = windowSafeAreaInsets?.bottom else { return }
        logOutButton.titleEdgeInsets = UIEdgeInsets(top: .zero, left: .zero, bottom: safeAreaBottomInset, right: .zero)
    }
}

extension HomeViewController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController == self {
            navigationController.setNavigationBarHidden(true, animated: false)
            navigationController.navigationBar.isHidden = true
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if navigationController.viewControllers.count >= 2 {
            navigationController.setNavigationBarHidden(false, animated: false)
            navigationController.navigationBar.isHidden = false
        }
    }
    
}
