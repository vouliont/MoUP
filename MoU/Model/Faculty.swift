import Foundation

class Faculty {
    
    let id: Int
    let name: String
    var foundedDate: Date?
    var siteUrl: String?
    var additionalInfo: String?
    var createdAt: Date?
    var updatedAt: Date?
    let cathedrasCount: Int
    
    init(id: Int, name: String, foundedDate: Date? = nil, siteUrl: String? = nil, additionalInfo: String? = nil, createdAt: Date? = nil, updatedAt: Date? = nil, cathedrasCount: Int) {
        self.id = id
        self.name = name
        self.foundedDate = foundedDate
        self.siteUrl = siteUrl
        self.additionalInfo = additionalInfo
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.cathedrasCount = cathedrasCount
    }
    
    static func parse(json: [String: Any]) -> Faculty? {
        guard let id = json["id"] as? Int,
            let name = json["name"] as? String
            else { return nil }
        
        
        let cathedrasCount: Int = {
            guard let cathedrasCountString = json["cathedras"] as? String else {
                return 0
            }
            return Int(cathedrasCountString) ?? 0
        }()
        
        let faculty = Faculty(id: id, name: name, cathedrasCount: cathedrasCount)
        
        if let foundedDate = json["foundedDate"] as? String {
            faculty.foundedDate = foundedDate.toDateFromISO8601()
        }
        if let siteUrl = json["siteUrl"] as? String {
            faculty.siteUrl = siteUrl
        }
        if let additionalInfo = json["addittionalInfo"] as? String {
            faculty.additionalInfo = additionalInfo
        }
        if let createdAt = json["createdAt"] as? Date {
            faculty.createdAt = createdAt
        }
        if let updatedAt = json["updatedAt"] as? Date {
            faculty.updatedAt = updatedAt
        }
        
        return faculty
    }
    
}
