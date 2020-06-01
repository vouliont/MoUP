import Foundation

class GeneralApi: BaseApi {
    
    override var requestErrors: [String : [Int : String]] {
        return [
            RequestList.deleteFaculty.name: [
                409: "CANNOT_DELETE_FACULTY"
            ],
            RequestList.deleteCathedra.name: [
                409: "CANNOT_DELETE_CATHEDRA"
            ]
        ]
    }
    
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
                        return (nil, self.errorForCode(response.code, of: RequestList.loadFacultiesList))
                    }
                    faculties.append(faculty)
                }
                let pagination = Pagination(currentPage: currentPage, totalPages: totalPages)
                return ((faculties, pagination), nil)
            }
            
            return (nil, self.errorForCode(response.code, of: RequestList.loadFacultiesList))
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
                    return (nil, self.errorForCode(response.code, of: RequestList.createFaculty))
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
                    return (nil, self.errorForCode(response.code, of: RequestList.editFaculty))
            }

            return (faculty, nil)
        }
    }
    
    func deleteFaculty(id: Int) -> Requester<Void> {
        return Requester(fullUrl("/faculty/\(id)"), method: .delete, headers: defaultHeaders) { response in
            guard response.code == 204 else {
                return (nil, self.errorForCode(response.code, of: RequestList.deleteFaculty))
            }
            
            return ((), nil)
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
                        return (nil, self.errorForCode(response.code, of: RequestList.loadCathedrasList))
                    }
                    cathedras.append(cathedra)
                }
                let pagination = Pagination(currentPage: currentPage, totalPages: totalPages)
                return ((cathedras, pagination), nil)
            }
            
            return (nil, self.errorForCode(response.code, of: RequestList.loadCathedrasList))
        }
    }
    
    func createCathedra(named name: String, foundedDate: String? = nil, siteUrl: String? = nil, additionalInfo: String? = nil, facultyId: Int) -> Requester<Cathedra> {
        var params: [String: Any] = [
            "name": name,
            "facultyId": facultyId
        ]
        params["foundedDate"] = foundedDate
        params["siteUrl"] = siteUrl
        params["addittionalInfo"] = additionalInfo
        
        return Requester(fullUrl("/cathedra"), method: .post, params: params, headers: defaultHeaders) { response in
            if response.code == 201,
                let jsonCathedra = response.json as? [String: Any],
                let cathedra = Cathedra.parse(json: jsonCathedra) {
                return (cathedra, nil)
            }
            
            return (nil, self.errorForCode(response.code, of: RequestList.createCathedra))
        }
    }
    
    func editCathedra(id: Int, name: String, foundedDate: String? = nil, siteUrl: String? = nil, additionalInfo: String? = nil, facultyId: Int) -> Requester<Cathedra> {
        var params: [String: Any] = [
            "name": name,
            "facultyId": facultyId
        ]
        params["foundedDate"] = foundedDate
        params["siteUrl"] = siteUrl
        params["addittionalInfo"] = additionalInfo
        
        return Requester(fullUrl("/cathedra/\(id)"), method: .put, params: params, headers: defaultHeaders) { response in
            if response.code == 200,
                let jsonCathedra = response.json as? [String: Any],
                let cathedra = Cathedra.parse(json: jsonCathedra) {
                return (cathedra, nil)
            }
            
            return (nil, self.errorForCode(response.code, of: RequestList.editCathedra))
        }
    }
    
    func deleteCathedra(id: Int) -> Requester<Void> {
        return Requester(fullUrl("/cathedra/\(id)"), method: .delete, headers: defaultHeaders) { response in
            if response.code == 204 {
                return ((), nil)
            }
            
            return (nil, self.errorForCode(response.code, of: RequestList.deleteCathedra))
        }
    }
    
    func loadGroupsList(forCathedraId cathedraId: Int, page: Int = 1) -> Requester<([Group], pagination: Pagination)> {
        let params: [String: Any] = [
            "cathedraId": cathedraId
        ]
        
        return Requester(fullUrl("/group/list"), method: .get, params: params, headers: defaultHeaders) { response in
            guard let json = response.json as? [String: Any],
                let groupsJson = json["groups"] as? [[String: Any]]
                else { return (nil, self.errorForCode(response.code, of: RequestList.loadGroupsList)) }
            
            let currentPage = (json["page"] as? Int) ?? 1
            let totalPages = (json["totalPages"] as? Int) ?? 1
            
            var groups = [Group]()
            for groupJson in groupsJson {
                guard let group = Group.parse(groupJson) else { return (nil, self.errorForCode(response.code, of: RequestList.loadGroupsList)) }
                
                groups.append(group)
            }
            
            let pagination = Pagination(currentPage: currentPage, totalPages: totalPages)
            
            return ((groups, pagination: pagination), nil)
        }
    }
    
    func createGroup(named name: String, numberOfSemesters: Int, cathedraId: Int) -> Requester<Group> {
        let params: [String: Any] = [
            "name": name,
            "numberOfSemesters": numberOfSemesters,
            "cathedraId": cathedraId
        ]
        
        return Requester(fullUrl("/group"), method: .post, params: params, headers: defaultHeaders) { response in
            guard response.code == 201,
                let groupJson = response.json as? [String: Any],
                let group = Group.parse(groupJson)
                else { return (nil, self.errorForCode(response.code, of: RequestList.createGroup)) }
            
            return (group, nil)
        }
    }
    
    func editGroup(id: Int, name: String, numberOfSemesters: Int, cathedraId: Int) -> Requester<Group> {
        let params: [String: Any] = [
            "name": name,
            "numberOfSemesters": numberOfSemesters,
            "cathedraId": cathedraId
        ]
        
        return Requester(fullUrl("/group/\(id)"), method: .put, params: params, headers: defaultHeaders) { response in
            guard response.code == 200,
                let groupJson = response.json as? [String: Any],
                let group = Group.parse(groupJson)
                else { return (nil, self.errorForCode(response.code, of: RequestList.editGroup)) }
            
            return (group, nil)
        }
    }
    
    func deleteGroup(id: Int) -> Requester<Void> {
        return Requester(fullUrl("/group/\(id)"), method: .delete, headers: defaultHeaders) { response in
            if response.code == 204 {
                return ((), nil)
            }
            
            return (nil, self.errorForCode(response.code, of: RequestList.deleteGroup))
        }
    }
    
}

extension GeneralApi {
    enum RequestList: String, Request {
        case loadFacultiesList, createFaculty, editFaculty, deleteFaculty
        case loadCathedrasList, createCathedra, editCathedra, deleteCathedra
        case loadGroupsList, createGroup, editGroup, deleteGroup
        
        var name: String {
            return self.rawValue
        }
    }
}
