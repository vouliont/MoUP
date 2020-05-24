import Foundation

struct CathedraCellData {
    enum CellType: String {
        case cathedraCell = "cathedraCell"
        case loadingCell = "loadingCell"
    }
    let cathedra: Cathedra?
    let cellIdentifier: CellType
}
