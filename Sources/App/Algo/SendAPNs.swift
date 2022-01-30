//
//  SendAPNs.swift
//  
//
//  Created by 朱浩宇 on 2022/1/30.
//

import Foundation
import Vapor
import Fluent
import APNS

func SendAPNs(_ apnsObject: Request.APNS, file: File, ignore: String?, allAPNs: [String]) throws {
    DispatchQueue.global().async {
        for apns in allAPNs where apns != ignore {
            try? apnsObject.send(
                .init(title: "Update", subtitle: try file.requireID().uuidString),
                to: apns
            ).wait()
        }
    }
}
