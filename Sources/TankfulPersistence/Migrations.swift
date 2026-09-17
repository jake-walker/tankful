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
    // v1 - initial schema
    static let v1 = Migration(
        version: 1,
        up: [
            """
            CREATE TABLE vehicle (
                id TEXT PRIMARY KEY,
                make TEXT,
                model TEXT,
                year INTEGER,
                fuelType TEXT NOT NULL
            )
            """,
            """
            CREATE TABLE fuelLog (
                id TEXT PRIMARY KEY,
                vehicleID TEXT NOT NULL,
                date TEXT NOT NULL,
                odometerMetres INTEGER,
                volumeLitres REAL,
                costMinorUnits INTEGER NOT NULL,
                currencyCode TEXT NOT NULL,
                filled INTEGER NOT NULL,
                missedLast INTEGER NOT NULL,
                notes TEXT,
            
                FOREIGN KEY(vehicleID) REFERENCES vehicle(id)
            )
            """
        ],
        down: [
            "DROP TABLE fuelLog",
            "DROP TABLE vehicle"
        ]
    )
    
    static let v2 = Migration(
        version: 2,
        up: [
            "ALTER TABLE vehicle ADD COLUMN remoteID TEXT",
            "ALTER TABLE vehicle ADD COLUMN syncState TEXT NOT NULL DEFAULT 'created'",
            "ALTER TABLE fuelLog ADD COLUMN remoteID TEXT",
            "ALTER TABLE fuelLog ADD COLUMN syncState TEXT NOT NULL DEFAULT 'created'"
        ],
        down: [
            "ALTER TABLE fuelLog DROP COLUMN syncState",
            "ALTER TABLE fuelLog DROP COLUMN remoteID",
            "ALTER TABLE vehicle DROP COLUMN syncState",
            "ALTER TABLE vehicle DROP COLUMN remoteID"
        ]
    )

    // v3 - store fuel log dates as epoch seconds for indexed range queries
    static let v3 = Migration(
        version: 3,
        up: [
            """
            CREATE TABLE fuelLog_v3 (
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
            """
            INSERT INTO fuelLog_v3 (
                id, vehicleID, date, odometerMetres, volumeLitres,
                costMinorUnits, currencyCode, filled, missedLast, notes,
                remoteID, syncState
            )
            SELECT
                id, vehicleID, CAST(strftime('%s', date) AS INTEGER),
                odometerMetres, volumeLitres, costMinorUnits, currencyCode,
                filled, missedLast, notes, remoteID, syncState
            FROM fuelLog
            """,
            "DROP TABLE fuelLog",
            "ALTER TABLE fuelLog_v3 RENAME TO fuelLog",
            "CREATE INDEX fuelLog_vehicleID_date ON fuelLog (vehicleID, date)"
        ],
        down: [
            "DROP INDEX fuelLog_vehicleID_date",
            """
            CREATE TABLE fuelLog_v2 (
                id TEXT PRIMARY KEY,
                vehicleID TEXT NOT NULL,
                date TEXT NOT NULL,
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
            """
            INSERT INTO fuelLog_v2 (
                id, vehicleID, date, odometerMetres, volumeLitres,
                costMinorUnits, currencyCode, filled, missedLast, notes,
                remoteID, syncState
            )
            SELECT
                id, vehicleID, strftime('%Y-%m-%dT%H:%M:%SZ', date, 'unixepoch'),
                odometerMetres, volumeLitres, costMinorUnits, currencyCode,
                filled, missedLast, notes, remoteID, syncState
            FROM fuelLog
            """,
            "DROP TABLE fuelLog",
            "ALTER TABLE fuelLog_v2 RENAME TO fuelLog"
        ]
    )
    
    static let all: [Migration] = [
        v1,
        v2,
        v3
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
