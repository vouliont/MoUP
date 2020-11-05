import Foundation

struct LessonCellData: LoadingCellProtocol {
    typealias Item = Lesson
    
    var item: Lesson?
    var cellType: CellType
}
