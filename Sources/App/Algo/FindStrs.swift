//
//  FindStrs.swift
//  
//
//  Created by 朱浩宇 on 2021/12/19.
//

import Foundation
import Fluent

func FindStrs(_ strs: [String], db: PackedDB, file: File) async throws -> [String : [File.FileContent]] {
    var res = [String : [File.FileContent]]()
    
    if file.isDictionary {
        res = try await withThrowingTaskGroup(of: [String : [File.FileContent]].self) { group in
            for sub in try await file.$sub.query(on: db.db).all() {
                group.addTask {
                    return try await FindStrs(strs, db: db, file: sub)
                }
            }
            
            var innerRes = [String : [File.FileContent]]()
            
            for try await result in group {
                for value in result {
                    if innerRes[value.key] == nil {
                        innerRes[value.key] = value.value
                    } else {
                        innerRes[value.key]?.append(contentsOf: value.value)
                    }
                }
            }
            
            return innerRes
        }
    }
    
    for str in strs {
        if file.name.contains(str) {
            if res[str] == nil {
                res[str] = [try await file.content(db.db)]
            } else {
                res[str]?.append(try await file.content(db.db))
            }
        }
    }
    
    return res
}
