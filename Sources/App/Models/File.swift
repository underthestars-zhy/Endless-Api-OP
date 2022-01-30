//
//  File.swift
//  
//
//  Created by 朱浩宇 on 2021/12/2.
//

import Foundation
import Fluent
import Vapor

final class File: Model, @unchecked Sendable {
    static var schema: String = "File"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "isDictionary")
    var isDictionary: Bool
    
    @Children(for: \.$father)
    var sub: [File]
    
    @Group(key: "storage")
    var storage: Storage
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "real")
    var real: UUID?
    
    @Field(key: "size")
    var size: Int64? // bytes
    
    @OptionalParent(key: "father")
    var father: File?
    
    @Field(key: "other")
    var other: [KeyValue]
    
    init() {}
    
    init(id: UUID? = nil, isDictionary: Bool, storage: Storage? = nil, name: String, real: UUID? = nil, size: Int64?) {
        self.id = id
        self.isDictionary = isDictionary
        self.storage = storage ?? Storage(drive: .test, tokenUUID: UUID())
        self.name = name
        self.real = real
        self.size = size
        self.other = []
    }
    
    func getFile(_ db: Database) async throws -> UUID {
        if let real = self.real {
            if let file = try await File.query(on: db).filter(\.$id == real).first() {
                return try await file.getFile(db)
            } else {
                return UUID()
            }
        } else {
            return try requireID()
        }
    }
    
    func content(_ db: Database) async throws -> FileContent {
        if let real = real {
            if let file = try await File.query(on: db).filter(\.$id == real).first() {
                return FileContent(uuid: try self.requireID(), name: self.name, isDictionary: self.isDictionary, storage: self.storage, size: try await getSize(db), _file: try await file.getFile(db))
            } else {
                throw Abort(.notFound)
            }
        } else {
            return FileContent(uuid: try self.requireID(), name: self.name, isDictionary: self.isDictionary, storage: self.storage, size: try await getSize(db), _file: nil)
        }
    }
    
    func getSize(_ db: Database) async throws -> Int64? {
        if isDictionary {
            return .init(try await $sub.query(on: db).count())
        } else {
            return size
        }
    }
    
    struct FileContent: Content, Sendable {
        let uuid: UUID
        let name: String
        let isDictionary: Bool
        let storage: Storage
        let size: Int64?
        let _file: UUID?
    }
}

extension File: Content {}

struct CreateFile: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("File")
            .id()
            .field("isDictionary", .string)
            .field("father", .uuid)
            .field("storage_drive", .string)
            .field("storage_token-uuid", .uuid)
            .field("name", .string)
            .field("real", .uuid)
            .field("file", .uuid)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("File").delete()
    }
}

struct UpdateFile: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("File")
            .field("size", .int64)
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("File").delete()
    }
}

struct UpdateFile2: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("File")
            .field("other", .int64)
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("File").delete()
    }
}
