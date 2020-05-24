import Foundation

class Cathedra {
    
    let id: Int
    let name: String
    var foundedDate: Date?
    var siteUrl: String?
    var additionalInfo: String?
    var createdAt: Date?
    var updatedAt: Date?
    let facultyId: Int
    let groupsCount: Int
    
    init(id: Int, name: String, foundedDate: Date? = nil, siteUrl: String? = nil, additionalInfo: String? = nil, createdAt: Date? = nil, updatedAt: Date? = nil, facultyId: Int, groupsCount: Int) {
        self.id = id
        self.name = name
        self.foundedDate = foundedDate
        self.siteUrl = siteUrl
        self.additionalInfo = additionalInfo
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.facultyId = facultyId
        self.groupsCount = groupsCount
    }
    
    static func parse(json: [String: Any]) -> Cathedra? {
        guard let id = json["id"] as? Int,
            let name = json["name"] as? String,
            let facultyId = json["facultyId"] as? Int
            else { return nil }
        
        let groupsCount: Int = {
            guard let groupsCountString = json["groups"] as? String else {
                return 0
            }
            return Int(groupsCountString) ?? 0
        }()
        
        let cathedra = Cathedra(id: id, name: name, facultyId: facultyId, groupsCount: groupsCount)
        
        if let foundedDateString = json["foundedDate"] as? String {
            cathedra.foundedDate = foundedDateString.toDateFromISO8601()
        }
        if let siteUrl = json["siteUrl"] as? String {
            cathedra.siteUrl = siteUrl
        }
        if let additionalInfo = json["addittionalInfo"] as? String {
            cathedra.additionalInfo = additionalInfo
        }
        if let createdAtString = json["createdAt"] as? String {
            cathedra.createdAt = createdAtString.toDateFromISO8601()
        }
        if let updatedAtString = json["updatedAt"] as? String {
            cathedra.updatedAt = updatedAtString.toDateFromISO8601()
        }
        
        return cathedra
    }
    
}
