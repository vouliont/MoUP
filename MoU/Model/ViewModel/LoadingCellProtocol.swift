import Foundation

protocol LoadingCellProtocol {
    associatedtype Item
    
    var item: Item? { get set }
    var cellType: CellType { get set }
}
