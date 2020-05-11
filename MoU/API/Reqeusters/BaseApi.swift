import Foundation

class BaseApi: NSObject {
    
    var fullUrl: (String) -> String
    var errorCodes: [Int: String] {
        return [
            403: "NO_INTERNET"
        ]
    }
    var defaultHeaders: [String: String] = [:]
    
    init(baseUrl: String) {
        fullUrl = { path in
            return baseUrl + path
        }
    }
    
    final func errorForCode(_ code: Int) -> ApiError {
        if let errorMessage = errorCodes[code] {
            return ApiError(code: code, message: errorMessage)
        }
        return ApiError.general
    }
    
}
