//
//  User.swift
//  
//
//  Created by 朱浩宇 on 2021/11/20.
//

import Vapor
import Fluent
import Foundation
import FluentSQL

final class User: Model, @unchecked Sendable {
    static var schema: String = "User"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "apple-identifier")
    var identifier: String
    
    @Field(key: "root-file")
    var root: UUID
    
    @Field(key: "removed")
    var removed: [RemovedItem]
    
    @Field(key: "apns")
    var apns: [String]
    
    @Field(key: "other")
    var other: [KeyValue]
    
    init() {}
    
    init(id: UUID? = nil, name: String, email: String, identifier: String, file: File, apns: [String] = []) throws {
        self.id = id
        self.name = name
        self.email = email
        self.identifier = identifier
        self.root = try file.requireID()
        self.removed = []
        self.apns = apns
        self.other = []
    }
}

struct RemovedItem: Codable, Content {
    var superFile: UUID
    var file: UUID
}

extension User: Content {}

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("User")
            .id()
            .field("name", .string)
            .field("email", .string)
            .field("apple-identifier", .string)
            .field("root-file", .uuid)
            .field("removed", .array)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("User").delete()
    }
}

struct UpdateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("User")
            .field("apns", .array)
            .update()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("User").delete()
    }
}

struct UpdateUser2: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("User")
            .field("other", .array)
            .update()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("User").delete()
    }
}
