import Foundation

struct ApiError: Error {
    let code: Int
    let message: String
    var localizedMessage: String {
        return message.localized
    }
    
    static let general = ApiError(code: 0, message: "GENERAL_ERROR")
    
    init(code: Int, message: String) {
        self.code = code
        self.message = "API_ERROR_".appending(message)
    }
}
