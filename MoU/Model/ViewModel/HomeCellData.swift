import Foundation

struct HomeCellData {
    
    enum Segue: String {
        case faculties = "facultiesListSegue"
    }
    
    let title: String
    var localizedTitle: String {
        return title.localized
    }
    let segue: Segue
    var segueValue: String {
        return segue.rawValue
    }
    
}
