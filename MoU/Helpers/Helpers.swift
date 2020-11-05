import Foundation

class Helpers {
    static func amountWithCurrency(_ amount: Float) -> String {
        String(format: "AMOUNT_CURRENCY".localized, amount).split(separator: ".").joined(separator: ",")
    }
}
