import Foundation

class Payment {
    let id: Int
    let change: Float
    let balance: Float
    let date: Date
    let studentId: Int64
    
    var actionType: ActionType {
        return change > 0 ? .balanceRecharge : .payTuition
    }
    
    init(id: Int, change: Float, balance: Float, date: Date, studentId: Int64) {
        self.id = id
        self.change = change
        self.balance = balance
        self.date = date
        self.studentId = studentId
    }
    
    static func parse(json: [String: Any]) -> Payment? {
        guard let id = json["id"] as? Int,
            let changeString = json["change"] as? String,
            let change = Float(changeString),
            let balanceString = json["balance"] as? String,
            let balance = Float(balanceString),
            let dateString = json["createdAt"] as? String,
            let date = dateString.toDateFromISO8601(),
            let studentId = json["studentId"] as? Int64
            else { return nil }
        
        return Payment(id: id, change: change, balance: balance, date: date, studentId: studentId)
    }
}

extension Payment {
    enum ActionType {
        case payTuition
        case balanceRecharge
    }
}
