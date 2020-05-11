import Foundation

struct ApiError: Error {
    let code: Int
    let message: String
    
    static let general = ApiError(code: 0, message: "GENERAL_ERROR")
    
    var localizedDescription: String {
        return "API_ERROR_".appending(message).localized
    }
}
