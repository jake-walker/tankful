//
//  Migrations.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

struct Migration: Sendable {
    let version: Int64
    let up: [String]
    let down: [String]
}

enum Migrations {
    /// v1 - initial schema
    static let v1 = Migration(
        version: 1,
        up: [
            """
            CREATE TABLE vehicle (
                id TEXT PRIMARY KEY,
                name TEXT,
                make TEXT,
                model TEXT,
                year INTEGER,
                fuelType TEXT NOT NULL,
                remoteID TEXT,
                syncState TEXT NOT NULL
            )
            """,
            """
            CREATE TABLE fuelLog (
                id TEXT PRIMARY KEY,
                vehicleID TEXT NOT NULL,
                date INTEGER NOT NULL,
                odometerMetres INTEGER,
                volumeLitres REAL,
                costMinorUnits INTEGER NOT NULL,
                currencyCode TEXT NOT NULL,
                filled INTEGER NOT NULL,
                missedLast INTEGER NOT NULL,
                notes TEXT,
                remoteID TEXT,
                syncState TEXT NOT NULL,

                FOREIGN KEY(vehicleID) REFERENCES vehicle(id)
            )
            """,
        ],
        down: [
            "DROP TABLE fuelLog",
            "DROP TABLE vehicle",
        ]
    )

    static let all: [Migration] = [
        v1,
    ]
}

extension TankfulDatabase {
    func migrate() throws {
        for migration in Migrations.all {
            if ctx.userVersion < migration.version {
                print("Migrating database to \(migration.version)")

                try ctx.transaction {
                    for statement in migration.up {
                        try ctx.exec(sql: statement)
                    }
                    ctx.userVersion = migration.version
                }
            }
        }
    }
}
