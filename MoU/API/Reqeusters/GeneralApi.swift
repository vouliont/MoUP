import Foundation

class GeneralApi: BaseApi {
    
    override var requestErrors: [String : [Int : String]] {
        return [
            RequestList.deleteFaculty.name: [
                409: "CANNOT_DELETE_FACULTY"
            ],
            RequestList.deleteCathedra.name: [
                409: "CANNOT_DELETE_CATHEDRA"
            ],
            RequestList.deleteGroup.name: [
                409: "CANNOT_DELETE_GROUP"
            ],
            RequestList.createUser.name: [
                409: "CANNOT_CREATE_USER"
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
            "cathedraId": cathedraId,
            "page": page
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
    
    func loadLessonsList(name: String? = nil, groupId: Int? = nil, teacherId: Int? = nil, page: Int = 1) -> Requester<([Lesson], pagination: Pagination)> {
        var params: [String: Any] = [
            "page": page
        ]
        params["name"] = name
        params["groupId"] = groupId
        params["teacherId"] = teacherId
        
        return Requester(fullUrl("/lesson/list"), method: .get, params: params, headers: defaultHeaders) { response in
            guard let json = response.json as? [String: Any],
                let lessonsJson = json["lessons"] as? [[String: Any]]
                else { return (nil, self.errorForCode(response.code, of: RequestList.loadLessonsList)) }
            
            let currentPage = (json["page"] as? Int) ?? 1
            let totalPages = (json["totalPages"] as? Int) ?? 1
            
            var lessons = [Lesson]()
            for lessonJson in lessonsJson {
                guard let lesson = Lesson.parse(from: lessonJson) else {
                    return (nil, self.errorForCode(response.code, of: RequestList.loadLessonsList))
                }
                lessons.append(lesson)
            }
            
            let pagination = Pagination(currentPage: currentPage, totalPages: totalPages)
            
            return ((lessons, pagination: pagination), nil)
        }
    }
    
    func createLesson(named name: String,/* semester: Int,*/ teacherId: Int64) -> Requester<Lesson> {
        let params: [String: Any] = [
            "name": name,
//            "semester": semester,
            "teacherId": teacherId
        ]
        
        return Requester(fullUrl("/lesson"), method: .post, params: params, headers: defaultHeaders) { response in
            guard response.code == 201,
                let lessonJson = response.json as? [String: Any],
                let lesson = Lesson.parse(from: lessonJson)
                else { return (nil, self.errorForCode(response.code, of: RequestList.createLesson)) }
            
            return (lesson, nil)
        }
    }
    
    func setLessonGroups(lessonId: Int, groupIds: [Int]) -> Requester<Lesson> {
        let params: [String: Any] = [
            "groupsIds": groupIds
        ]
        
        return Requester(fullUrl("/lesson/\(lessonId)/set-groups"), method: .post, params: params, headers: defaultHeaders) { response in
            guard response.code == 200,
                let lessonJson = response.json as? [String: Any],
                let lesson = Lesson.parse(from: lessonJson)
                else { return (nil, self.errorForCode(response.code, of: RequestList.editLesson)) }
            
            return (lesson, nil)
        }
    }
    
    func editLesson(id: Int, name: String,/* semester: Int,*/ teacherId: Int64) -> Requester<Lesson> {
        let params: [String: Any] = [
            "name": name,
//            "semester": semester,
            "teacherId": teacherId
        ]
        
        return Requester(fullUrl("/lesson/\(id)"), method: .put, params: params, headers: defaultHeaders) { response in
            guard response.code == 200,
                let lessonJson = response.json as? [String: Any],
                let lesson = Lesson.parse(from: lessonJson)
                else { return (nil, self.errorForCode(response.code, of: RequestList.editLesson)) }
            
            return (lesson, nil)
        }
    }
    
    func deleteLesson(id: Int) -> Requester<Void> {
        return Requester(fullUrl("/lesson/\(id)"), method: .delete, headers: defaultHeaders) { response in
            guard response.code == 204 else {
                return (nil, self.errorForCode(response.code, of: RequestList.deleteLesson))
            }
            
            return ((), nil)
        }
    }
    
    func loadUsersList(
        email: String? = nil,
        role: User.Role? = .none,
        groupId: Int? = nil,
        learnFormId: Int? = nil,
        cathedraId: Int? = nil,
        facultyId: Int? = nil,
        page: Int = 1
    ) -> Requester<([User], pagination: Pagination)> {
        var params: [String: Any] = [
            "page": page
        ]
        
        switch role {
        case .admin:
            params["email"] = email
        case .student:
            params["groupId"] = groupId
            params["learnFormId"] = learnFormId
            params["cathedraId"] = cathedraId
            params["facultyId"] = facultyId
        case .teacher:
            params["cathedraId"] = cathedraId
            params["facultyId"] = facultyId
        case .none:
            break
        }
        
        return Requester(fullUrl("/user/list"), method: .get, params: params, headers: defaultHeaders) { response in
            guard let json = response.json as? [String: Any],
                let usersJson = json["users"] as? [[String: Any]]
                else { return (nil, self.errorForCode(response.code, of: RequestList.loadUsersList)) }
            
            let currentPage = (json["page"] as? Int) ?? 1
            let totalPages = (json["totalPages"] as? Int) ?? 1

            var users = [User]()
            for userJson in usersJson {
                guard let user = User.parse(json: userJson) else {
                    return (nil, self.errorForCode(response.code, of: RequestList.loadUsersList))
                }
                users.append(user)
            }
            
            let pagination = Pagination(currentPage: currentPage, totalPages: totalPages)
            
            return ((users, pagination: pagination), nil)
        }
    }
    
    func createUser(
        firstName: String,
        lastName: String,
        middleName: String,
        loginName: String,
        email: String,
        role: User.Role,
        birthday: String,
        password: String,
        cathedraId: Int? = nil,
        groupId: Int? = nil,
        learnFormId: Int? = nil
    ) -> Requester<User> {
        var params: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "middleName": middleName,
            "loginName": loginName,
            "email": email,
            "roleName": role.rawValue,
            "birthday": birthday,
            "password": password
        ]
        
        switch role {
        case .student:
            params["groupId"] = groupId
            params["learnFormId"] = learnFormId
        case .teacher:
            params["cathedraId"] = cathedraId
        default: break
        }
        
        return Requester(fullUrl("/user"), method: .post, params: params, headers: defaultHeaders) { response in
            guard var userJson = response.json as? [String: Any] else {
                return (nil, self.errorForCode(response.code, of: RequestList.createUser))
            }
            
            // lifehack, do not repeat
            switch role {
            case .student:
                if userJson["student"] != nil { break }
                let studentJson: [String: Any] = [
                    "groupId": groupId!,
                    "learnFormId": learnFormId!
                ]
                userJson["student"] = studentJson
            case .teacher:
                if userJson["teacher"] != nil { break }
                let teacherJson: [String: Any] = [
                    "cathedraId": cathedraId!
                ]
                userJson["teacker"] = teacherJson
            default: break
            }
            
            guard let user = User.parse(json: userJson) else {
                return (nil, self.errorForCode(response.code, of: RequestList.createUser))
            }
            
            return (user, nil)
        }
    }
    
    func updateUser(
        id: Int,
        firstName: String,
        lastName: String,
        middleName: String,
        loginName: String,
        email: String,
        currentRole: User.Role,
        birthday: String,
        cathedraId: Int? = nil,
        groupId: Int? = nil,
        learnFormId: Int? = nil
    ) -> Requester<User> {
        var params: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "middleName": middleName,
            "loginName": loginName,
            "email": email,
            "birthday": birthday
        ]
        
        switch currentRole {
        case .student:
            params["groupId"] = groupId
            params["learnFormId"] = learnFormId
        case .teacher:
            params["cathedraId"] = cathedraId
        default: break
        }
        
        return Requester(fullUrl("/user/\(id)/data"), method: .put, params: params, headers: defaultHeaders) { response in
            guard var userJson = response.json as? [String: Any] else {
                return (nil, self.errorForCode(response.code, of: RequestList.editUser))
            }
            
            // lifehack, do not repeat
            switch currentRole {
            case .student:
                if userJson["student"] != nil { break }
                let studentJson: [String: Any] = [
                    "groupId": groupId!,
                    "learnFormId": learnFormId!
                ]
                userJson["student"] = studentJson
            case .teacher:
                if userJson["teacher"] != nil { break }
                let teacherJson: [String: Any] = [
                    "cathedraId": cathedraId!
                ]
                userJson["teacker"] = teacherJson
            default: break
            }
            
            guard let user = User.parse(json: userJson) else {
                return (nil, self.errorForCode(response.code, of: RequestList.editUser))
            }
            
            return (user, nil)
        }
    }
    
    func deleteUser(id: Int) -> Requester<Void> {
        return Requester(fullUrl("/user/\(id)"), method: .delete, headers: defaultHeaders) { response in
            guard response.code == 204 else {
                return (nil, self.errorForCode(response.code, of: RequestList.deleteUser))
            }
            
            return ((), nil)
        }
    }
    
}

extension GeneralApi {
    enum RequestList: String, Request {
        case loadFacultiesList, createFaculty, editFaculty, deleteFaculty
        case loadCathedrasList, createCathedra, editCathedra, deleteCathedra
        case loadGroupsList, createGroup, editGroup, deleteGroup
        case loadLessonsList, createLesson, setLessonGroups, editLesson, deleteLesson
        case loadUsersList, createUser, editUser, deleteUser
        
        var name: String {
            return self.rawValue
        }
    }
}
