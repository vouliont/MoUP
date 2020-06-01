import Foundation

class BaseApi: NSObject {
    
    var fullUrl: (String) -> String
    var requestErrors: [String: [Int: String]] {
        return [
            RequestList.all.name: [
                403: "NO_INTERNET"
            ]
        ]
    }
    var defaultHeaders: [String: String] = [:]
    
    init(baseUrl: String) {
        fullUrl = { path in
            return baseUrl + path
        }
    }
    
    final func errorForCode(_ code: Int, of request: Request) -> ApiError {
        if let errorCodes = requestErrors[request.name],
            let errorMessage = errorCodes[code] {
            return ApiError(code: code, message: errorMessage)
        }
        return ApiError.general
    }
    
}

extension BaseApi {
    enum RequestList: String, Request {
        case all
        
        var name: String {
            return self.rawValue
        }
    }
}

protocol Request {
    var name: String { get }
}
