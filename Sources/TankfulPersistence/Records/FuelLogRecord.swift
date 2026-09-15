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
    
    public var date: String
    static let date = SQLColumn(name: "date", type: .text, nullable: false)
    
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
    
    public static let table = SQLTable(name: "fuelLog", columns: [id, vehicleID, date, odometerMetres, volumeLitres, costMinorUnits, currencyCode, filled, missedLast, notes])
    
    public init(
        id: String,
        vehicleID: String,
        date: String,
        odometerMetres: Int64? = nil,
        volumeLitres: Double? = nil,
        costMinorUnits: Int64,
        currencyCode: String,
        filled: Int64,
        missedLast: Int64,
        notes: String? = nil
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
    }
    
    public init(
        row: SQLRow,
        context: SQLContext
    ) throws {
        self.id = try Self.id.textValueRequired(in: row)
        self.vehicleID = try Self.vehicleID.textValueRequired(in: row)
        self.date = try Self.date.textValueRequired(in: row)
        self.odometerMetres = Self.odometerMetres.longValue(in: row)
        self.volumeLitres = Self.volumeLitres.realValue(in: row)
        self.costMinorUnits = try Self.costMinorUnits.longValueRequired(in: row)
        self.currencyCode = try Self.currencyCode.textValueRequired(in: row)
        self.filled = try Self.filled.longValueRequired(in: row)
        self.missedLast = try Self.missedLast.longValueRequired(in: row)
        self.notes = Self.notes.textValue(in: row)
    }
    
    public func encode(row: inout SQLRow) throws {
        row[Self.id] = SQLValue(self.id)
        row[Self.vehicleID] = SQLValue(self.vehicleID)
        row[Self.date] = SQLValue(self.date)
        row[Self.odometerMetres] = SQLValue(self.odometerMetres)
        row[Self.volumeLitres] = SQLValue(self.volumeLitres)
        row[Self.costMinorUnits] = SQLValue(self.costMinorUnits)
        row[Self.currencyCode] = SQLValue(self.currencyCode)
        row[Self.filled] = SQLValue(self.filled)
        row[Self.missedLast] = SQLValue(self.missedLast)
        row[Self.notes] = SQLValue(self.notes)
    }
}
