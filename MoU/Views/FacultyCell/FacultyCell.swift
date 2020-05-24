import UIKit

class FacultyCell: UITableViewCell {
    
    static let identifier = "facultyCell"
    
    @IBOutlet var facultyNameLabel: UILabel!
    @IBOutlet var cathedrasCountLabel: UILabel!
    
    func reset(with faculty: Faculty) {
        facultyNameLabel.text = faculty.name
        cathedrasCountLabel.text = String(faculty.cathedrasCount)
    }
    
}
