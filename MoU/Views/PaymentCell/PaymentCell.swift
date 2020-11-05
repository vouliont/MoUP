import UIKit

class PaymentCell: UITableViewCell {
    
    static let identifier = CellType.paymentCell.rawValue
    
    private var payment: Payment?
    
    @IBOutlet var paymentSumLabel: UILabel!
    @IBOutlet var paymentBalanceLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    
    func reset(with payment: Payment) {
        self.payment = payment
        paymentSumLabel.text = "\(Helpers.amountWithCurrency(payment.change))"
        paymentSumLabel.textColor = textColor()
        paymentBalanceLabel.text = "\(Helpers.amountWithCurrency(payment.balance))"
        dateLabel.text = payment.date.toDefaultFormattedString()
    }
    
    private func textColor() -> UIColor {
        switch payment?.actionType {
        case .balanceRecharge:
            return UIColor.systemGreen
        case .payTuition:
            return UIColor.systemRed
        default:
            return .clear
        }
    }
}
