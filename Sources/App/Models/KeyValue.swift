//
//  File 2.swift
//  
//
//  Created by 朱浩宇 on 2022/1/25.
//

import Foundation
import Fluent
import Vapor

struct KeyValue: Codable, Content, Sendable {
    let key: String
    let value: String
}
