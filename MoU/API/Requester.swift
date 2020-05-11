import Foundation
import RxSwift

class Requester<T> {
    
    typealias SuccessHandler = (T) -> Void
    typealias ErrorHandler = (ApiError) -> Void
    typealias CompletionHandler = (T?, ApiError?) -> Void
    
    enum HttpMethod: String {
        case post = "POST"
        case get = "GET"
    }
    
    private var successHandler: SuccessHandler?
    private var errorHandler: ErrorHandler?
    private var completionHandler: CompletionHandler?
    
    struct JsonResponse {
        let code: Int
        let json: [String: Any]
        let error: Error?
    }
    
    init(
        _ urlString: String,
        method: HttpMethod,
        params: [String: Any]? = nil,
        headers: [String: String] = [:],
        completion: @escaping (_ response: JsonResponse) -> (T?, ApiError?))
    {
        let url = URL(string: urlString)!
        var urlRequest = URLRequest(url: url)
        
        urlRequest.httpMethod = method.rawValue
        
        var copiedHeaders = headers
        copiedHeaders["charset"] = "utf-8"
        addDefaultHeaders(to: &copiedHeaders)
        for (key, value) in copiedHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        if let params = params {
            urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: params)
        }
        
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            let json: [String: Any] = {
                if let data = data {
                    return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
                }
                return [:]
            }()
            
            let jsonResponse = JsonResponse(code: code, json: json, error: error)
            let (result, apiError) = completion(jsonResponse)
            
            self.resolve(result: result, error: apiError)
        }
        
        dataTask.resume()
    }
    
    private func resolve(result: T? = nil, error: ApiError? = nil) {
        if let result = result {
            successHandler?(result)
        } else if let error = error {
            errorHandler?(error)
        }
        completionHandler?(result, error)
    }
    
    func success(_ handler: @escaping SuccessHandler) -> Requester {
        successHandler = handler
        return self
    }
    
    func error(_ handler: @escaping ErrorHandler) -> Requester {
        errorHandler = handler
        return self
    }
    
    func complete(_ handler: @escaping CompletionHandler) -> Requester {
        completionHandler = handler
        return self
    }
    
    private func addDefaultHeaders(to headers: inout [String: String]) {
        headers["Accept"] = "application/json"
        headers["Content-Type"] = "application/json"
    }
    
    func asSingle() -> Single<T> {
        return Single.create { single in
            let _ = self.success { result in
                single(.success(result))
            }.error { error in
                single(.error(error))
            }
            
            return Disposables.create()
        }
    }
    
}
