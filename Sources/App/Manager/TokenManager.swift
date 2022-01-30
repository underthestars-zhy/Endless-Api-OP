//
//  TokenManager.swift
//  
//
//  Created by 朱浩宇 on 2021/11/29.
//

import Foundation
import Fluent
import Vapor

actor TokenManager {
    static var shared: TokenManager!
    
    private(set) var items: [Token]
    
    static func SetUp(_ db: PackedDB) throws {
        let tm = try TokenManager(db)
        shared = tm
    }
    
    init(_ db: PackedDB) throws {
        self.items = try Token.query(on: db.db).all().wait()
    }
    
    static subscript(_ drive: Drive) -> UUID? {
        get async {
            try? await shared.items.filter { token in
#warning("Your drive's max size (Byte), and delete `return false`")
//                token.type == drive && token.size <= 0
                return false
            }.randomElement()?.requireID()
        }
    }
    
    static subscript(_ uuid: UUID) -> Token? {
        get async {
            try? await shared.items.first { token in
                try token.requireID() == uuid
            }
        }
    }
    
    func add(_ token: Token) {
        items.append(token)
    }
}
