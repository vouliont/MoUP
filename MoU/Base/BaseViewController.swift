import UIKit
import RxSwift

class BaseViewController: UIViewController {

    let disposeBag = DisposeBag()

}

class BaseTableViewController: UITableViewController {
    
    let disposeBag = DisposeBag()
    
}
