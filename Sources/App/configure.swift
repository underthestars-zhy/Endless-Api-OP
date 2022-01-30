import Vapor
import Fluent
import FluentSQLiteDriver
import NIOPosix
import APNS

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // register routes
    
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    app.migrations.add(CreateUser())
    app.migrations.add(CreateToken())
    app.migrations.add(CreateFile())
    app.migrations.add(CreateShare())
    
    app.migrations.add(UpdateUser())
    app.migrations.add(UpdateFile())
    
    app.migrations.add(UpdateUser2())
    app.migrations.add(UpdateFile2())
    app.migrations.add(UpdateShare())
    
    #warning("Custom port and host")
    app.http.server.configuration.port = 0000
    #if !os(Linux)
    app.http.server.configuration.hostname = "your local ip"
    #endif
    
    #warning("Your apns key (from Apple)")
    let AuthKey = ""

    app.apns.configuration = try .init(
        authenticationMethod: .jwt(
            key: .private(pem: AuthKey),
            keyIdentifier: "your_key",
            teamIdentifier: "your_team"
        ),
        topic: "your_topict",
        environment: { () -> APNSwiftConfiguration.Environment in
            #if os(Linux)
            return .production
            #else
            return .sandbox
            #endif
        }()
    )
    
    try app.autoMigrate().wait()
    try TokenManager.SetUp(PackedDB(db: app.db))
    
    try routes(app)
}
