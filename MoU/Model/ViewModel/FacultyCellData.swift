import Foundation

struct FacultyCellData {
    enum CellType: String {
        case facultyCell = "facultyCell"
        case loadingCell = "loadingCell"
    }
    
    let faculty: Faculty?
    let cellIdentifier: CellType
}

