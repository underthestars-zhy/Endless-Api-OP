//
//  File.swift
//  
//
//  Created by 朱浩宇 on 2022/1/7.
//

import Foundation

func FindSuitableName(_ name: String, count: Int? = nil, subs: [File]) -> String {
    let _name = { () -> String in
        if let count = count {
            return (name as NSString).deletingPathExtension + " - \(count)." + (name as NSString).pathExtension
        }
        
        return name
    }()
    
    if Eliminate(_name, subs, \File.name) {
        return FindSuitableName(name, count: (count ?? 0) + 1, subs: subs)
    }
    
    return _name
}
