//
//  Size.swift
//  
//
//  Created by 朱浩宇 on 2021/12/10.
//

import Foundation
import Fluent

func Size(_ file: File, db: PackedDB) async throws -> Int64 {
    if file.isDictionary {
        return try await withThrowingTaskGroup(of: Int64.self, body: { group -> Int64 in
            for sub in try await file.$sub.query(on: db.db).all() {
                group.addTask {
                    return try await Size(sub, db: db)
                }
            }
            
            return try await group.reduce(0, +)
        })
    } else {
        return file.size ?? 0
    }
}
