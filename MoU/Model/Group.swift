import Foundation

class Group {
    let id: Int
    var name: String
    var numberOfSemesters: Int
    let cathedraId: Int
    let createdAt: Date!
    var updatedAt: Date!
    var countStudents: Int = 0
    
    init(id: Int, name: String, cathedraId: Int, numberOfSemesters: Int, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.name = name
        self.cathedraId = cathedraId
        self.numberOfSemesters = numberOfSemesters
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    static func parse(_ json: [String: Any]) -> Group? {
        guard let id = json["id"] as? Int,
            let name = json["name"] as? String,
            let cathedraId = json["cathedraId"] as? Int,
            let numberOfSemesters = json["numberOfSemesters"] as? Int,
            let createdAtString = json["createdAt"] as? String,
            let updatedAtString = json["updatedAt"] as? String
            else { return nil }
        
        let group = Group(
            id: id,
            name: name,
            cathedraId: cathedraId,
            numberOfSemesters: numberOfSemesters,
            createdAt: createdAtString.toDateFromISO8601()!,
            updatedAt: updatedAtString.toDateFromISO8601()!
        )
        
        if let countStudents = json["students"] as? Int {
            group.countStudents = countStudents
        }
        
        return group
    }
}
