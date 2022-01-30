//
//  Token.swift
//  
//
//  Created by 朱浩宇 on 2021/11/29.
//

import Foundation
import Fluent

final class Token: Model, @unchecked Sendable {
    static var schema: String = "Token"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "token")
    var token: Data
    
    @Field(key: "drive")
    var type: Drive
    
    @Field(key: "size")
    var size: Int64
    
    init() {}
    
    init(id: UUID? = nil, token: Data, type: Drive, size: Int64 = 0) {
        self.id = id
        self.token = token
        self.type = type
        self.size = size
    }
}

struct CreateToken: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("Token")
            .id()
            .field("token", .data)
            .field("drive", .string)
            .field("size", .int64)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("Token").delete()
    }
}
