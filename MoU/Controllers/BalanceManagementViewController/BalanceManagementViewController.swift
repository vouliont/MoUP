import UIKit

class BalanceManagementViewController: TemporaryNavBarViewController {
    
    @IBOutlet var topViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var balanceLabel: UILabel!
    @IBOutlet var rechargeBalanceButton: UIButton!
    @IBOutlet var historyTableView: UITableView!
    @IBOutlet var payHeaderView: UIView!
    
    private let viewModel = BalanceManagementViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        
        bind(output: viewModel.transform(input: BalanceManagementViewModel.Input(
            viewDidDisappear: self.rx.viewDidDisappear
        )))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        topViewTopConstraint.constant = navigationBarHeight
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        topViewTopConstraint.constant = 0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier {
        case BalanceManagementViewModel.Segue.rechargeBalance:
            segue.destination.isModalInPresentation = true
        default:
            break
        }
    }
    
    private func bind(output: BalanceManagementViewModel.Output) {
        historyTableView.rx.itemSelected
            .bind(onNext: { [unowned self] indexPath in
                self.historyTableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)
        
        output.historyBalance
            .drive(historyTableView.rx.items) { [unowned self] tableView, row, paymentCellData in
                if paymentCellData.cellType == .loadingCell {
                    self.viewModel.loadMorePaymentsSubject.onNext(())
                }
                let cell = self.cell(for: paymentCellData)
                cell.separatorInset.left = paymentCellData.cellType == .loadingCell ? UIScreen.main.bounds.width : 16
                return cell
            }.disposed(by: disposeBag)
        
        output.historyBalance
            .map { $0.isEmpty ? "EMPTY_HISTORY".localized : nil }
            .drive(onNext: historyTableView.setEmptyTitle(_:))
            .disposed(by: disposeBag)
        
        output.balance
            .drive(balanceLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
}

// MARK: - HELPER FUNCTIONS
extension BalanceManagementViewController {
    private func setupTableView() {
        historyTableView.register(UINib(nibName: "LoadingCell", bundle: nil), forCellReuseIdentifier: LoadingCell.identifier)
        historyTableView.register(UINib(nibName: "PaymentCell", bundle: nil), forCellReuseIdentifier: PaymentCell.identifier)
        historyTableView.tableFooterView = UIView(frame: .zero)
    }
    
    private func cell(for data: PaymentCellData) -> UITableViewCell {
        switch data.cellType {
        case .paymentCell:
            let paymentCell = historyTableView.dequeueReusableCell(withIdentifier: data.cellType.rawValue) as! PaymentCell
            paymentCell.reset(with: data.item!)
            return paymentCell
        case .loadingCell:
            let loadingCell = historyTableView.dequeueReusableCell(withIdentifier: data.cellType.rawValue) as! LoadingCell
            loadingCell.activityIndicator.startAnimating()
            return loadingCell
        default:
            return UITableViewCell()
        }
    }
}
