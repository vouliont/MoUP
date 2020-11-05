import UIKit

class LessonCell: UITableViewCell {
    
    static let identifier = CellType.lessonCell.rawValue
    
    @IBOutlet var lessonNameLabel: UILabel!
    @IBOutlet var teacherNameLabel: UILabel!
    
    func reset(with lesson: Lesson) {
        lessonNameLabel.text = lesson.name
        teacherNameLabel.text = lesson.teacher.fullName
    }
}
