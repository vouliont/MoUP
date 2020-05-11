import Foundation

extension String {
    
    func toDateFromISO8601() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return dateFormatter.date(from: self)
    }
    
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
}
