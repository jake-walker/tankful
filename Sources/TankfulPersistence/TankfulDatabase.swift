//
//  TankfulDatabase.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

import Foundation
import SkipSQLCore
import SkipSQLPlus

public final class TankfulDatabase {
    public let ctx: SQLContext

    public init(ctx: SQLContext) {
        self.ctx = ctx
    }
}

public extension TankfulDatabase {
    static func live(at databaseURL: URL) throws -> TankfulDatabase {
        print("Using database at \(databaseURL.path(percentEncoded: false))")

        let ctx = try SQLContext(
            path: databaseURL.path(percentEncoded: false),
            flags: [.create, .readWrite],
            configuration: .plus
        )

        let database = TankfulDatabase(ctx: ctx)
        try database.migrate()
        return database
    }

    static func inMemory() throws -> TankfulDatabase {
        let ctx = try SQLContext(
            path: ":memory:",
            flags: [.create, .readWrite],
            configuration: .plus
        )

        let database = TankfulDatabase(ctx: ctx)
        try database.migrate()
        return database
    }
}
