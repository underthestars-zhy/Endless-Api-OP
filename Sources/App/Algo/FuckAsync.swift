//
//  FuckAsync.swift
//  
//
//  Created by 朱浩宇 on 2022/1/28.
//

import Vapor
import Fluent

extension UUID: @unchecked Sendable {}
extension Application: @unchecked Sendable {}

struct PackedDB: @unchecked Sendable {
    let db: Database
}
