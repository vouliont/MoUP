import UIKit

class FacultyCell: UITableViewCell {
    
    static let identifier = CellType.facultyCell.rawValue
    
    @IBOutlet var facultyNameLabel: UILabel!
    @IBOutlet var cathedrasCountLabel: UILabel!
    
    func reset(with faculty: Faculty) {
        facultyNameLabel.text = faculty.name
        cathedrasCountLabel.text = String(faculty.cathedrasCount)
    }
    
}
