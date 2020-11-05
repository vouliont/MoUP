import UIKit

class GroupCell: UITableViewCell {
    
    static let identifier = CellType.groupCell.rawValue
    
    @IBOutlet var groupNameLabel: UILabel!
    @IBOutlet var studentsCountLabel: UILabel!
    
    func reset(with group: Group) {
        groupNameLabel.text = group.name
        studentsCountLabel.text = String(group.studentsCount)
    }
}
