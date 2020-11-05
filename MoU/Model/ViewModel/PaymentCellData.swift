import Foundation

struct PaymentCellData: LoadingCellProtocol {
    typealias Item = Payment
    
    var item: Payment?
    var cellType: CellType
}
