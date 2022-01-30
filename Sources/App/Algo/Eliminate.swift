//
//  Eliminate.swift
//  
//
//  Created by 朱浩宇 on 2022/1/7.
//

import Foundation

func Eliminate<T, V: Equatable>(_ item: V, _ contents: [T], _ keypath: KeyPath<T, V>) -> Bool {
    for content in contents {
        if content[keyPath: keypath] == item {
            return true
        }
    }
    
    return false
}
