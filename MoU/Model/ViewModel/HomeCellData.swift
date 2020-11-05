import Foundation

struct HomeCellData {
    
    enum Segue: String {
        // for admin
        case faculties = "facultiesListSegue"
        case lessons = "lessonsListSegue"
        // for student
        case balanceManagement = "balanceManagementSegue"
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
