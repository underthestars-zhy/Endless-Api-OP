//
//  Subs.swift
//  
//
//  Created by 朱浩宇 on 2021/12/13.
//

import Foundation
import Fluent

func Subs(_ file: File, db: PackedDB) async throws -> [File] {
    if file.isDictionary {
        return try await withThrowingTaskGroup(of: [File].self) { group in
            for sub in try await file.$sub.query(on: db.db).all() {
                group.addTask {
                    try await Subs(sub, db: db)
                }
            }
            
            return try await group.reduce([], +)
        }
    } else {
        return [file]
    }
}
