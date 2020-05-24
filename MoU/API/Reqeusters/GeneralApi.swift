import Foundation

class GeneralApi: BaseApi {
    
    func loadFacultiesList(page: Int = 1) -> Requester<([Faculty], pagination: Pagination)> {
        let params: [String: Any] = [
            "page": page
        ]
        
        return Requester(fullUrl("/faculty/list"), method: .get, params: params, headers: defaultHeaders) { response in
            if let json = response.json as? [String: Any],
                let facultiesJson = json["faculties"] as? [[String: Any]]
            {
                let currentPage = (json["page"] as? Int) ?? 1
                let totalPages = (json["totalPages"] as? Int) ?? 1
                
                var faculties = [Faculty]()
                for facultyJson in facultiesJson {
                    guard let faculty = Faculty.parse(json: facultyJson) else {
                        return (nil, self.errorForCode(response.code))
                    }
                    faculties.append(faculty)
                }
                let pagination = Pagination(currentPage: currentPage, totalPages: totalPages)
                return ((faculties, pagination), nil)
            }
            
            return (nil, self.errorForCode(response.code))
        }
    }
    
    func loadCathedrasList(facultyId: Int? = nil, page: Int = 1) -> Requester<([Cathedra], pagination: Pagination)> {
        var params: [String: Any] = [
            "page": page
        ]
        params["facultyId"] = facultyId
        
        return Requester(fullUrl("/cathedra/list"), method: .get, params: params, headers: defaultHeaders) { response in
            if let json = response.json as? [String: Any],
                let cathedrasJson = json["cathedras"] as? [[String: Any]]
            {
                let currentPage = (json["page"] as? Int) ?? 1
                let totalPages = (json["totalPages"] as? Int) ?? 1
                
                var cathedras = [Cathedra]()
                for cathedraJson in cathedrasJson {
                    guard let cathedra = Cathedra.parse(json: cathedraJson) else {
                        return (nil, self.errorForCode(response.code))
                    }
                    cathedras.append(cathedra)
                }
                let pagination = Pagination(currentPage: currentPage, totalPages: totalPages)
                return ((cathedras, pagination), nil)
            }
            
            return (nil, self.errorForCode(response.code))
        }
    }
    
    func createFaculty(named name: String, foundedDate: String? = nil, siteUrl: String? = nil, additionalInfo: String? = nil) -> Requester<Faculty> {
        var params: [String: Any] = [
            "name": name,
        ]
        params["foundedDate"] = foundedDate
        params["siteUrl"] = siteUrl
        params["addittionalInfo"] = additionalInfo
        
        return Requester(fullUrl("/faculty"), method: .post, params: params, headers: defaultHeaders) { response in
            guard response.code == 201,
                let facultyJson = response.json as? [String: Any],
                let faculty = Faculty.parse(json: facultyJson)
                else {
                return (nil, self.errorForCode(response.code))
            }
            
            return (faculty, nil)
        }
    }
    
    func editFaculty(id: Int, name: String, foundedDate: String? = nil, siteUrl: String? = nil, additionalInfo: String? = nil) -> Requester<Faculty> {
        var params: [String: Any] = [
            "name": name,
        ]
        params["foundedDate"] = foundedDate
        params["siteUrl"] = siteUrl
        params["addittionalInfo"] = additionalInfo

        return Requester(fullUrl("/faculty/\(id)"), method: .put, params: params, headers: defaultHeaders) { response in
            guard response.code == 200,
                let facultyJson = response.json as? [String: Any],
                let faculty = Faculty.parse(json: facultyJson)
                else {
                return (nil, self.errorForCode(response.code))
            }

            return (faculty, nil)
        }
    }
    
    func deleteFaculty(id: Int) -> Requester<Void> {
        return Requester(fullUrl("/faculty/\(id)"), method: .delete, headers: defaultHeaders) { response in
            guard response.code == 204 else {
                return (nil, self.errorForCode(response.code))
            }
            
            return ((), nil)
        }
    }
    
}
