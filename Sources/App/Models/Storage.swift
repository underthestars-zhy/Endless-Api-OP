//
//  Storage.swift
//  
//
//  Created by 朱浩宇 on 2021/12/2.
//

import Foundation
import Fluent
import Vapor

final class Storage: Fields, Content, @unchecked Sendable {
    init() {}
    
    @Field(key: "drive")
    var drive: Drive
    
    @Field(key: "token-uuid")
    var tokenUUID: UUID
    
    init(drive: Drive, tokenUUID: UUID) {
        self.drive = drive
        self.tokenUUID = tokenUUID
    }
}
