//
//  TankfulDatabase.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

import SkipSQLCore
import SkipSQL
import Foundation

public final class TankfulDatabase {
    public let ctx: SQLContext
    
    public init(ctx: SQLContext) {
        self.ctx = ctx
    }
}

public extension TankfulDatabase {
    static func defaultDatabaseURL() throws -> URL {
        let directory = URL.applicationSupportDirectory.appendingPathComponent("Tankful", isDirectory: true)
        
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        
        return directory.appendingPathComponent("Tankful.sqlite")
    }
    
    static func live(at databaseURL: URL) throws -> TankfulDatabase {
        print("Using database at \(databaseURL.path(percentEncoded: false))")
        
        let ctx = try SQLContext(
            path: databaseURL.path(percentEncoded: false),
            flags: [.create, .readWrite],
            configuration: .platform
        )
        
        let database = TankfulDatabase(ctx: ctx)
        try database.migrate()
        return database
    }
    
    static func live() throws -> TankfulDatabase {
        let databaseURL = try defaultDatabaseURL()
        return try live(at: databaseURL)
    }
    
    static func inMemory() throws -> TankfulDatabase {
        let ctx = try SQLContext(
            path: ":memory:",
            flags: [.create, .readWrite],
            configuration: .platform
        )
        
        let database = TankfulDatabase(ctx: ctx)
        try database.migrate()
        return database
    }
}
