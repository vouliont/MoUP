import UIKit

extension UITableView {
    func setEmptyTitle(_ title: String?) {
        if let title = title {
            let backgroundView = UIView(frame: self.bounds)
            let titleLabel = UILabel(frame: .zero)
            titleLabel.numberOfLines = 1
            titleLabel.text = title
            titleLabel.sizeToFit()
            titleLabel.center = CGPoint(x: backgroundView.bounds.width / 2, y: backgroundView.bounds.height / 2)
            backgroundView.addSubview(titleLabel)
            self.backgroundView = backgroundView
        } else {
            self.backgroundView = nil
        }
    }
}
