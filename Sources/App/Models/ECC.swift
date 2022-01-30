//
//  ECC.swift
//  
//
//  Created by 朱浩宇 on 2021/12/16.
//

import Foundation
import Vapor

#warning("Your AES 256 key")
let publicKey = ""

struct ECC: Content, Sendable {
    let data: Data
}

extension Data: @unchecked Sendable {}
