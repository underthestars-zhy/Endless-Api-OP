//
//  Share.swift
//  
//
//  Created by 朱浩宇 on 2021/12/20.
//

import Foundation
import Fluent
import Vapor

final class Share: Model, @unchecked Sendable {
    static var schema: String = "Share"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "file")
    var file: UUID
    
    @Field(key: "overdue")
    var overdue: Date?
    
    @Field(key: "other")
    var other: [KeyValue]
    
    var isOverdue: Bool {
        if let overdue = overdue {
            return Date() > overdue
        } else {
            return false
        }
    }
    
    init(id: UUID? = nil, file: UUID, overdue: Date? = nil) {
        self.id = id
        self.file = file
        self.overdue = overdue
        self.other = []
    }
    
    init() {
        
    }
}

struct CreateShare: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("Share")
            .id()
            .field("file", .uuid)
            .field("overdue", .date)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("Share").delete()
    }
}

struct UpdateShare: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("Share")
            .field("other", .array)
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("Share").delete()
    }
}
