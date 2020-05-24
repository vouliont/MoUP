import UIKit

class CathedraCell: UITableViewCell {
    
    @IBOutlet var cathedraNameLabel: UILabel!
    @IBOutlet var groupsCountLabel: UILabel!
    
    func reset(with cathedra: Cathedra) {
        cathedraNameLabel.text = cathedra.name
        groupsCountLabel.text = String(cathedra.groupsCount)
    }
}
