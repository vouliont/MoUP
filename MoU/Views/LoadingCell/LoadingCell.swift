import UIKit

class LoadingCell: UITableViewCell {
    
    static let identifier = CellType.loadingCell.rawValue
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
}
