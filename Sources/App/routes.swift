import Vapor
import Fluent
import Foundation
import CollectionConcurrencyKit
#if canImport(SwiftECC)
import SwiftECC
#endif

func routes(_ app: Application) throws {
    #warning("Your register path")
    app.post("") { req -> [String : String] in
        struct Model: Content {
            let name: String
            let email: String
            let identifier: String
        }
        
        let data = try req.content.decode(Model.self)
        
        let file = File(isDictionary: true, name: "root", size: nil)
        try await file.create(on: req.db)
        
        let users = try await User.query(on: req.db)
            .filter(\.$identifier == data.identifier)
            .all()
        
        try await users.asyncForEach { user in
            try await user.delete(on: req.db)
        }
        
        let user = try User(name: data.name, email: data.email, identifier: data.identifier, file: file)
        try await user.create(on: req.db)
        
        return ["name" : user.name, "email" : user.email, "identifier" : user.identifier]
    }
    
#warning("Your check path")
    app.post("check") { req -> EventLoopFuture<Int> in
        struct Model: Content {
            let identifier: String
        }
        
        let data = try req.content.decode(Model.self)
        
        let count = User.query(on: req.db)
            .filter(\.$identifier == data.identifier)
            .count()
        
        
        return count
    }
    
#warning("Your root file check path")
    app.post("check_root_file") { req -> Int in
        struct Model: Content {
            let rootFile: UUID
        }
        
        let data = try req.content.decode(Model.self)
        
        return try await User.query(on: req.db)
            .filter(\.$root == data.rootFile)
            .count()
    }
    
    #if canImport(SwiftECC)
#warning("Your token create path")
    app.post("") { req -> HTTPStatus in
        struct Model: Content {
            let token: String
            let drive: Drive
        }
        
        let data = try req.content.decode(Model.self)
        
        let pubKey = try ECPublicKey(pem: publicKey)
        
        guard let text = data.token.data(using: .utf8) else { throw Abort(.notFound) }
        let encryptedData = pubKey.encrypt(msg: text, cipher: .AES256)
        
        let token = Token(token: encryptedData, type: data.drive)
        
        try await token.create(on: req.db)
        
        await TokenManager.shared.add(token)
        
        return .created
    }
    #else
#warning("Your token create path")
    app.post("") { req -> HTTPStatus in
        struct Model: Content {
            let token: Data
            let drive: Drive
        }
        
        let data = try req.content.decode(Model.self)
        
        let token = Token(token: data.token, type: data.drive)
        
        try await token.create(on: req.db)
        
        await TokenManager.shared.add(token)
        
        return .created
    }
    #endif
    
#warning("Your get token uuid path")
    app.get("", ":drive") { req -> String in
        guard let drive = req.parameters.get("drive"), let driveFromStr = Drive(rawValue: drive) else { throw Abort(.badRequest) }
        guard let res = await TokenManager[driveFromStr]?.uuidString else { throw Abort(.notFound) }
        
        return res
    }
    
#warning("Your get token path")
    app.post("") { req -> ECC in
        struct Model: Content {
            let uuid: String
        }
        
        let data = try req.content.decode(Model.self)
        
        guard let uuid = UUID(uuidString: data.uuid) else { throw Abort(.badRequest) }
        guard let res = await TokenManager[uuid] else { throw Abort(.notFound) }
        
        return ECC(data: res.token)
    }
    
#warning("Your get root file path")
    app.post("") { req -> [File.FileContent] in
        struct Model: Content {
            let identifier: String
        }
        
        let data = try req.content.decode(Model.self)
        
        guard let user = try await User.query(on: req.db)
                .filter(\.$identifier == data.identifier)
                .first() else { throw Abort(.notFound) }
        
        guard let file = try await File.query(on: req.db)
                .filter(\.$id == user.root)
                .first() else { throw Abort(.notFound) }
        
        guard file.isDictionary else { throw Abort(.badRequest) }
        
        return try await file.$sub.query(on: req.db).all().asyncMap { file in
            try await file.content(req.db)
        }
    }
    
#warning("Your get root uuid path")
    app.post("") { req -> String in
        struct Model: Content {
            var identifier: String
        }
        
        let data = try req.content.decode(Model.self)
        
        guard let user = try await User.query(on: req.db)
                .filter(\.$identifier == data.identifier)
                .first() else { throw Abort(.notFound) }
        
        guard let rootFile = try await File.query(on: req.db)
                .filter(\.$id == user.root)
                .first() else { throw Abort(.notFound) }
        
        guard rootFile.isDictionary else { throw Abort(.badRequest) }
        
        return try rootFile.requireID().uuidString
    }
    
#warning("Your add dictionary path")
    app.post("") { req -> File.FileContent in
        struct Model: Content, Sendable {
            let name: String
            let superFileUUID: UUID
            let apns: String?
            let identifier: String
        }
        
        let data = try req.content.decode(Model.self)
        
        guard let user = try await User.query(on: req.db)
                .filter(\.$identifier == data.identifier)
                .first() else { throw Abort(.notFound) }
        
        let superFile: File
        
        guard let _file = try await File.query(on: req.db)
                .filter(\.$id == data.superFileUUID)
                .first() else { throw Abort(.notFound) }
        
        superFile = _file
        
        let subs = try await superFile.$sub.query(on: req.db).all()
        
        let file = File(isDictionary: true, name: FindSuitableName(data.name, subs: subs), size: nil)
        
        try await superFile.$sub.create(file, on: req.db)
        
        try await superFile.update(on: req.db)
        
        try SendAPNs(req.apns, file: superFile, ignore: data.apns, allAPNs: user.apns)
        
        return try await file.content(req.db)
    }
    
#warning("Your get sub path")
    app.post("") { req -> [File.FileContent] in
        struct Model: Content {
            let superFileUUID: UUID
        }
        
        let data = try req.content.decode(Model.self)
        
        guard let file = try await File.query(on: req.db)
                .filter(\.$id == data.superFileUUID)
                .first() else { throw Abort(.notFound) }
        
        guard file.isDictionary else { throw Abort(.notFound) }
        
        return try await (await file.$sub.query(on: req.db).all()).asyncMap { file in
            try await file.content(req.db)
        }
    }
    
#warning("Your file adding path")
    app.post("") { req -> File.FileContent in
        struct Model: Content {
            let uuid: UUID?
            let name: String
            let drive: Drive
            let size: Int64 // Byte
            let tokenUUID: UUID
            let superFileUUID: UUID
            let apns: String?
            let identifier: String
        }
        
        let data = try req.content.decode(Model.self)
        
        guard let user = try await User.query(on: req.db)
                .filter(\.$identifier == data.identifier)
                .first() else { throw Abort(.notFound) }
        
        guard let superFile = try await File.query(on: req.db)
                .filter(\.$id == data.superFileUUID)
                .first() else { throw Abort(.notFound) }
        
        let subs = try await superFile.$sub.query(on: req.db).all()
        
        let file = File(id: data.uuid, isDictionary: false, storage: Storage(drive: data.drive, tokenUUID: data.tokenUUID), name: FindSuitableName(data.name, subs: subs), size: data.size)
        
        try await superFile.$sub.create(file, on: req.db)
        try await superFile.update(on: req.db)
        
        guard let token = try await Token.query(on: req.db)
                .filter(\.$id == data.tokenUUID)
                .first() else { throw Abort(.notFound) }
        
        token.size += data.size
        
        await TokenManager[data.tokenUUID]?.size += data.size
        
        try await token.update(on: req.db)
        
        try SendAPNs(req.apns, file: superFile, ignore: data.apns, allAPNs: user.apns)
        
        return try await file.content(req.db)
    }
    
#warning("Your token size getting path")
    app.post("get_token_size") { req -> Int64 in // Byte
        struct Model: Content {
            let tokenUUID: UUID
        }
        
        let data = try req.content.decode(Model.self)
        
        guard let token = await TokenManager[data.tokenUUID] else { throw Abort(.notFound) }
        
        return token.size
    }
    
#warning("Your folder size getting path")
    app.post("") { req -> Int64 in
        struct Model: Content {
            let superFileUUID: UUID
            let identifier: String
        }
        
        let data = try req.content.decode(Model.self)
        
        guard let superFile = try await File.query(on: req.db)
                .filter(\.$id == data.superFileUUID)
                .first() else { throw Abort(.notFound) }
        
        guard let user = try await User.query(on: req.db)
                .filter(\.$identifier == data.identifier)
                .first() else { throw Abort(.notFound) }
        
        let removedSize = try await Subs(superFile, db: PackedDB(db: req.db))
            .filter { file in try user.removed.contains { try $0.file == file.requireID() } }
            .compactMap { $0.size }
            .reduce(0, +)
        
        return try await abs(Size(superFile, db: PackedDB(db: req.db)) - removedSize)
    }
    
#warning("Your removed file getting path")
    app.post("") { req -> [RemovedItem] in
        struct Model: Content {
            var identifier: String
        }
        
        let data = try req.content.decode(Model.self)
        
        guard let user = try await User.query(on: req.db)
                .filter(\.$identifier == data.identifier)
                .first() else { throw Abort(.notFound) }
        
        return user.removed
    }
    
#warning("Your remove file path")
    app.post("") { req -> [File.FileContent] in
        struct Model: Content, Sendable {
            var removeFile: UUID
            var superFile: UUID
            var identifier: String
            let apns: String?
        }
        
        let data = try req.content.decode(Model.self)
        
        guard let file = try await File.query(on: req.db)
                .filter(\.$id == data.removeFile)
                .first() else { throw Abort(.notFound) }
        
        guard let superFile = try await File.query(on: req.db)
                .filter(\.$id == data.superFile)
                .first() else { throw Abort(.notFound) }
        
        guard let user = try await User.query(on: req.db)
                .filter(\.$identifier == data.identifier)
                .first() else { throw Abort(.notFound) }
        
        file.$father.id = nil
        try await file.update(on: req.db)
        
        user.removed.append(RemovedItem(superFile: try superFile.requireID(), file: try file.requireID()))
        try await user.update(on: req.db)
        
        try SendAPNs(req.apns, file: superFile, ignore: data.apns, allAPNs: user.apns)
        
        return try await (await superFile.$sub.query(on: req.db).all()).asyncMap { file in
            try await file.content(req.db)
        }
    }
    
#warning("Your recover file path")
    app.post("") { req -> [File.FileContent] in
        struct Model: Content {
            var recoverFile: UUID
            var superFile: UUID
            var identifier: String
            let apns: String?
        }
        
        let data = try req.content.decode(Model.self)
        
        guard let user = try await User.query(on: req.db)
                .filter(\.$identifier == data.identifier)
                .first() else { throw Abort(.notFound) }
        
        user.removed.removeAll { item in
            item.superFile == data.superFile && item.file == data.recoverFile
        }
        
        try await user.update(on: req.db)
        
        guard let file = try await File.query(on: req.db)
                .filter(\.$id == data.recoverFile)
                .first() else { throw Abort(.notFound) }
        
        guard let superFile = try await File.query(on: req.db)
                .filter(\.$id == data.superFile)
                .first() else { throw Abort(.notFound) }
        
        file.$father.id = try superFile.requireID()
        try await file.update(on: req.db)
        
        try SendAPNs(req.apns, file: superFile, ignore: data.apns, allAPNs: user.apns)
        
        return try await (await superFile.$sub.query(on: req.db).all()).asyncMap { file in
            try await file.content(req.db)
        }
    }
    
#warning("Your copy file path")
    app.post("") { req -> [File.FileContent] in
        struct Model: Content {
            var from: UUID
            var toSuperFile: UUID
            var identifier: String
            let apns: String?
        }
        
        let data = try req.content.decode(Model.self)
        
        guard let user = try await User.query(on: req.db)
                .filter(\.$identifier == data.identifier)
                .first() else { throw Abort(.notFound) }
        
        guard let toSuperFile = try await File.query(on: req.db)
                .filter(\.$id == data.toSuperFile)
                .first() else { throw Abort(.notFound) }
        
        guard let fromFile = try await File.query(on: req.db)
                .filter(\.$id == data.from)
                .first() else { throw Abort(.notFound) }
        
        let toFile: File
        
        let subs = try await toSuperFile.$sub.query(on: req.db).all()
        
        if fromFile.isDictionary {
            toFile = File(isDictionary: true, name: FindSuitableName(fromFile.name, subs: subs), size: nil)
            
            func createRefer(_ fromFile: File, father: File) async throws {
                if fromFile.isDictionary {
                    for sub in try await fromFile.$sub.query(on: req.db).all() {
                        let _father = File(isDictionary: true, name: fromFile.name, size: nil)
                        try await father.$sub.create(_father, on: req.db)
                        try await createRefer(sub, father: _father)
                        try await _father.update(on: req.db)
                    }
                } else {
                    let file = File(isDictionary: false, storage: Storage(drive: fromFile.storage.drive, tokenUUID: fromFile.storage.tokenUUID), name: fromFile.name, real: try fromFile.requireID(), size: fromFile.size)
                    try await father.$sub.create(file, on: req.db)
                }
            }
            
            try await toSuperFile.$sub.create(toFile, on: req.db)
            
            for sub in try await fromFile.$sub.query(on: req.db).all() {
                try await createRefer(sub, father: toFile)
            }
            
            try await toFile.update(on: req.db)
        } else {
            toFile = File(isDictionary: false, storage: Storage(drive: fromFile.storage.drive, tokenUUID: fromFile.storage.tokenUUID), name: FindSuitableName(fromFile.name, subs: subs), real: try fromFile.requireID(), size: fromFile.size)
            
            try await toSuperFile.$sub.create(toFile, on: req.db)
        }
        
        try await toSuperFile.update(on: req.db)
        
        try SendAPNs(req.apns, file: toSuperFile, ignore: data.apns, allAPNs: user.apns)
        
        return try await (await toSuperFile.$sub.query(on: req.db).all()).asyncMap { file in
            try await file.content(req.db)
        }
    }
    
#warning("Your move file path")
    app.post("") { req -> [File.FileContent] in
        struct Model: Content {
            var from: UUID
            var toSuperFile: UUID
            var identifier: String
            let apns: String?
        }
        
        let data = try req.content.decode(Model.self)
        
        guard let user = try await User.query(on: req.db)
                .filter(\.$identifier == data.identifier)
                .first() else { throw Abort(.notFound) }
        
        guard let toSuperFile = try await File.query(on: req.db)
                .filter(\.$id == data.toSuperFile)
                .first() else { throw Abort(.notFound) }
        
        guard let fromFile = try await File.query(on: req.db)
                .filter(\.$id == data.from)
                .first() else { throw Abort(.notFound) }
        
        let temp = fromFile.$father.id
        
        fromFile.$father.id = try toSuperFile.requireID()
        
        let subs = try await toSuperFile.$sub.query(on: req.db).all()
        
        fromFile.name = FindSuitableName(fromFile.name, subs: subs)
        
        try await fromFile.update(on: req.db)
        
        if let superFile = try await File.query(on: req.db)
            .filter(\.$id == temp ?? UUID())
            .first() {
            try SendAPNs(req.apns, file: superFile, ignore: data.apns, allAPNs: user.apns)
        }
        
        return try await (await toSuperFile.$sub.query(on: req.db).all()).asyncMap { file in
            try await file.content(req.db)
        }
    }
    
#warning("Your file renaming path")
    app.post("") { req -> File.FileContent in
        struct Model: Content {
            var file: UUID
            var newName: String
            var identifier: String
            let apns: String?
        }
        
        let data = try req.content.decode(Model.self)
        
        guard let file = try await File.query(on: req.db)
                .filter(\.$id == data.file)
                .first() else { throw Abort(.notFound) }
        
        guard let user = try await User.query(on: req.db)
                .filter(\.$identifier == data.identifier)
                .first() else { throw Abort(.notFound) }
        
        guard let superFile = try await File.query(on: req.db)
                .filter(\.$id == file.$father.id ?? UUID())
                .first() else { throw Abort(.notFound) }
        
        let subs = try await superFile.$sub.query(on: req.db).all()
        
        file.name = FindSuitableName(data.newName, subs: subs)
        try await file.update(on: req.db)
        
        if let superFile = try await File.query(on: req.db)
            .filter(\.$id == file.$father.id ?? UUID())
            .first() {
            try SendAPNs(req.apns, file: superFile, ignore: data.apns, allAPNs: user.apns)
        }
        
        return try await file.content(req.db)
    }
    
#warning("Your file searching path")
    app.post("") { req -> [String : [File.FileContent]] in
        struct Model: Content {
            var identifier: String
            var search: [String]
        }
        
        let data = try req.content.decode(Model.self)
        
        guard let user = try await User.query(on: req.db)
                .filter(\.$identifier == data.identifier)
                .first() else { throw Abort(.notFound) }
        
        guard let file = try await File.query(on: req.db)
                .filter(\.$id == user.root)
                .first() else { throw Abort(.notFound) }
        
        return try await FindStrs(data.search, db: PackedDB(db: req.db), file: file)
    }
    
#warning("Your create share path")
    app.post("") { req -> String in
        struct Model: Content {
            var file: UUID
            var date: Date?
        }
        
        let data = try req.content.decode(Model.self)
        
        guard let file = try await File.query(on: req.db)
                .filter(\.$id == data.file)
                .first() else { throw Abort(.notFound) }
        
        let share = Share(file: try file.requireID(), overdue: data.date)
        try await share.create(on: req.db)
        
        return try share.requireID().uuidString
    }
    
#warning("Your add share file path")
    app.post("") { req -> [File.FileContent] in
        struct Model: Content, Sendable {
            var superFile: UUID
            var share: UUID
            var identifier: String
            let apns: String?
        }
        
        let data = try req.content.decode(Model.self)
        
        guard let user = try await User.query(on: req.db)
                .filter(\.$identifier == data.identifier)
                .first() else { throw Abort(.notFound) }
        
        guard let root = try await File.query(on: req.db)
                .filter(\.$id == user.root)
                .first() else { throw Abort(.notFound) }
        
        guard let toSuperFile = try await File.query(on: req.db)
                .filter(\.$id == data.superFile)
                .first() else { throw Abort(.notFound) }
        
        guard let share = try await Share.query(on: req.db)
                .filter(\.$id == data.share)
                .first() else { throw Abort(.notFound) }
        
        if share.isOverdue {
            throw Abort(.custom(code: 777, reasonPhrase: "Overdue"))
        }
        
        guard let fromFile = try await File.query(on: req.db)
                .filter(\.$id == share.file)
                .first() else { throw Abort(.notFound) }
        
        if try await Subs(root, db: PackedDB(db: req.db)).contains(where: { file in
            file.id == share.file
        }) {
            throw Abort(.custom(code: 778, reasonPhrase: "Overflow"))
        }
        
        let toFile: File
        
        let subs = try await toSuperFile.$sub.query(on: req.db).all()
        
        if fromFile.isDictionary {
            toFile = File(isDictionary: true, name: FindSuitableName(fromFile.name, subs: subs), size: nil)
            
            func createRefer(_ fromFile: File, father: File) async throws {
                if fromFile.isDictionary {
                    for sub in try await fromFile.$sub.query(on: req.db).all() {
                        let _father = File(isDictionary: true, name: fromFile.name, size: nil)
                        try await father.$sub.create(_father, on: req.db)
                        try await createRefer(sub, father: _father)
                        try await _father.update(on: req.db)
                    }
                } else {
                    let file = File(isDictionary: false, storage: Storage(drive: fromFile.storage.drive, tokenUUID: fromFile.storage.tokenUUID), name: fromFile.name, real: try fromFile.requireID(), size: fromFile.size)
                    try await father.$sub.create(file, on: req.db)
                }
            }
            
            try await toSuperFile.$sub.create(toFile, on: req.db)
            
            for sub in try await fromFile.$sub.query(on: req.db).all() {
                try await createRefer(sub, father: toFile)
            }
            
            try await toFile.update(on: req.db)
        } else {
            toFile = File(isDictionary: false, storage: Storage(drive: fromFile.storage.drive, tokenUUID: fromFile.storage.tokenUUID), name: FindSuitableName(fromFile.name, subs: subs), real: try fromFile.requireID(), size: fromFile.size)
            
            try await toSuperFile.$sub.create(toFile, on: req.db)
        }
        
        try await toSuperFile.update(on: req.db)
        
        try SendAPNs(req.apns, file: toSuperFile, ignore: data.apns, allAPNs: user.apns)
        
        return try await (await toSuperFile.$sub.query(on: req.db).all()).asyncMap { file in
            try await file.content(req.db)
        }
    }
    
#warning("Your remove removed file path")
    app.post("") { req -> [RemovedItem] in
        struct Model: Content {
            var removed: RemovedItem
            var identifier: String
        }
        
        let data = try req.content.decode(Model.self)
        
        guard let user = try await User.query(on: req.db)
                .filter(\.$identifier == data.identifier)
                .first() else { throw Abort(.notFound) }
        
        user.removed.removeAll {
            $0.file == data.removed.file && $0.superFile == data.removed.superFile
        }
        
        try await user.update(on: req.db)
        
        return user.removed
    }
    
#warning("Your add apns path")
    app.post("") { req -> HTTPStatus  in
        struct Model: Content {
            let identifier: String
            let apnsToken: String
            let old: String?
        }
        
        let data = try req.content.decode(Model.self)
        
        guard let user = try await User.query(on: req.db)
                .filter(\.$identifier == data.identifier)
                .first() else { throw Abort(.notFound) }
        
        user.apns.append(data.apnsToken)
        
        if let old = data.old {
            user.apns.removeAll {
                $0 == old
            }
        }
        
        user.apns = Set<String>(user.apns).map { $0 }
        
        try await user.update(on: req.db)
        
        
        return .ok
    }
    
#warning("Your delete user path")
    app.post("") { req -> HTTPStatus in
        struct Model: Content {
            let identifier: String
        }
        
        let data = try req.content.decode(Model.self)
        
        guard let user = try await User.query(on: req.db)
                .filter(\.$identifier == data.identifier)
                .first() else { return .badRequest }
        
        try await user.delete(on: req.db)
        
        return .ok
    }
}
