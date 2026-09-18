//
//  FuelLogRecord.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

import SkipSQLCore

public struct FuelLogRecord: SQLCodable, Equatable {
    public var id: String
    static let id = SQLColumn(name: "id", type: .text, primaryKey: true)

    public var vehicleID: String
    static let vehicleID = SQLColumn(name: "vehicleID", type: .text, nullable: false)

    public var date: Int64
    static let date = SQLColumn(name: "date", type: .long, nullable: false)

    public var odometerMetres: Int64?
    static let odometerMetres = SQLColumn(name: "odometerMetres", type: .long, nullable: true)

    public var volumeLitres: Double?
    static let volumeLitres = SQLColumn(name: "volumeLitres", type: .real, nullable: true)

    public var costMinorUnits: Int64
    static let costMinorUnits = SQLColumn(name: "costMinorUnits", type: .long, nullable: false)

    public var currencyCode: String
    static let currencyCode = SQLColumn(name: "currencyCode", type: .text, nullable: false)

    public var filled: Int64
    static let filled = SQLColumn(name: "filled", type: .long, nullable: false)

    public var missedLast: Int64
    static let missedLast = SQLColumn(name: "missedLast", type: .long, nullable: false)

    public var notes: String?
    static let notes = SQLColumn(name: "notes", type: .text, nullable: true)

    public var remoteID: String?
    static let remoteID = SQLColumn(name: "remoteID", type: .text, nullable: true)

    public var syncState: String
    static let syncState = SQLColumn(name: "syncState", type: .text, nullable: false)

    public static let table = SQLTable(name: "fuelLog", columns: [id, vehicleID, date, odometerMetres, volumeLitres, costMinorUnits, currencyCode, filled, missedLast, notes, remoteID, syncState])

    public init(
        id: String,
        vehicleID: String,
        date: Int64,
        odometerMetres: Int64?,
        volumeLitres: Double?,
        costMinorUnits: Int64,
        currencyCode: String,
        filled: Int64,
        missedLast: Int64,
        notes: String?,
        remoteID: String?,
        syncState: String
    ) {
        self.id = id
        self.vehicleID = vehicleID
        self.date = date
        self.odometerMetres = odometerMetres
        self.volumeLitres = volumeLitres
        self.costMinorUnits = costMinorUnits
        self.currencyCode = currencyCode
        self.filled = filled
        self.missedLast = missedLast
        self.notes = notes
        self.remoteID = remoteID
        self.syncState = syncState
    }

    public init(
        row: SQLRow,
        context _: SQLContext
    ) throws {
        id = try Self.id.textValueRequired(in: row)
        vehicleID = try Self.vehicleID.textValueRequired(in: row)
        date = try Self.date.longValueRequired(in: row)
        odometerMetres = Self.odometerMetres.longValue(in: row)
        volumeLitres = Self.volumeLitres.realValue(in: row)
        costMinorUnits = try Self.costMinorUnits.longValueRequired(in: row)
        currencyCode = try Self.currencyCode.textValueRequired(in: row)
        filled = try Self.filled.longValueRequired(in: row)
        missedLast = try Self.missedLast.longValueRequired(in: row)
        notes = Self.notes.textValue(in: row)
        remoteID = Self.remoteID.textValue(in: row)
        syncState = try Self.syncState.textValueRequired(in: row)
    }

    public func encode(row: inout SQLRow) throws {
        row[Self.id] = SQLValue(id)
        row[Self.vehicleID] = SQLValue(vehicleID)
        row[Self.date] = SQLValue(date)
        row[Self.odometerMetres] = SQLValue(odometerMetres)
        row[Self.volumeLitres] = SQLValue(volumeLitres)
        row[Self.costMinorUnits] = SQLValue(costMinorUnits)
        row[Self.currencyCode] = SQLValue(currencyCode)
        row[Self.filled] = SQLValue(filled)
        row[Self.missedLast] = SQLValue(missedLast)
        row[Self.notes] = SQLValue(notes)
        row[Self.remoteID] = SQLValue(remoteID)
        row[Self.syncState] = SQLValue(syncState)
    }
}
