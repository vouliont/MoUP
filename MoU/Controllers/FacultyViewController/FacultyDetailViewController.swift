import UIKit
import RxSwift

class FacultyDetailsViewController: BaseViewController {
    
    @IBOutlet var facultyNameLabel: UILabel!
    @IBOutlet var foundedDateLabel: UILabel!
    @IBOutlet var linkImageView: UIImageView!
    @IBOutlet var additionalInfoLabel: UILabel!
    @IBOutlet var cathedrasTableView: UITableView!
    
    private let viewModel = FacultyDetailsViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bind(output: viewModel.transform(input: FacultyDetailsViewModel.Input()))
    }
    
    private func bind(output: FacultyDetailsViewModel.Output) {
        
    }
    
}

extension FacultyDetailsViewController {
    func setFaculty(_ faculty: Faculty) {
        viewModel.facultySubject.accept(faculty)
    }
}
