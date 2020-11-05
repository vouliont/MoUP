import Foundation
import CoreData

class Lesson {
    let id: Int
    var name: String
    var teacher: Teacher
    var groups = [Group]()
    
    init(id: Int, name: String, teacher: Teacher) {
        self.id = id
        self.name = name
        self.teacher = teacher
    }
    
    static func parse(from json: [String: Any]) -> Lesson? {
        guard let id = json["id"] as? Int,
            let name = json["name"] as? String,
            let teacherJson = json["teacher"] as? [String: Any],
            let teacherId = teacherJson["id"] as? Int64,
            let teacherDetailsJson = teacherJson["user"] as? [String: Any],
            let teacherFirstName = teacherDetailsJson["firstName"] as? String,
            let teacherLastName = teacherDetailsJson["lastName"] as? String,
            let teacherMiddleName = teacherDetailsJson["middleName"] as? String,
            let teacherEmail = teacherDetailsJson["email"] as? String
            else { return nil }
        
        let teacher = Teacher(entity: NSEntityDescription.entity(forEntityName: "Teacher", in: App.shared.dataStack.mainContext)!, insertInto: nil)
        teacher.id = teacherId
        teacher.firstName = teacherFirstName
        teacher.lastName = teacherLastName
        teacher.middleName = teacherMiddleName
        teacher.email = teacherEmail
        
        let lesson = Lesson(id: id, name: name, teacher: teacher)
        
        if let groupsJson = json["groupLesson"] as? [[String: Any]] {
            var groups = [Group]()
            for groupJson in groupsJson {
                if let groupDetailsJson = groupJson["group"] as? [String: Any],
                    let group = Group.parse(groupDetailsJson) {
                    groups.append(group)
                }
            }
            lesson.groups = groups
        }
        
        return lesson
    }
}
