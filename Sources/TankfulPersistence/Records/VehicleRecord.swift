//
//  VehicleRecord.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

import SkipSQLCore

public struct VehicleRecord: SQLCodable, Equatable {
    public var id: String
    static let id = SQLColumn(name: "id", type: .text, primaryKey: true)
    
    public var make: String?
    static let make = SQLColumn(name: "make", type: .text, nullable: true)
    
    public var model: String?
    static let model = SQLColumn(name: "model", type: .text, nullable: true)
    
    public var year: Int64?
    static let year = SQLColumn(name: "year", type: .long, nullable: true)
    
    public var fuelType: String
    static let fuelType = SQLColumn(name: "fuelType", type: .text, nullable: false)
    
    public var remoteID: String?
    static let remoteID = SQLColumn(name: "remoteID", type: .text, nullable: true)
    
    public var syncState: String
    static let syncState = SQLColumn(name: "syncState", type: .text, nullable: false)
    
    public static let table = SQLTable(name: "vehicle", columns: [id, make, model, year, fuelType, remoteID, syncState])
    
    public init(
        id: String,
        make: String?,
        model: String?,
        year: Int64?,
        fuelType: String,
        remoteID: String?,
        syncState: String
    ) {
        self.id = id
        self.make = make
        self.model = model
        self.year = year
        self.fuelType = fuelType
        self.remoteID = remoteID
        self.syncState = syncState
    }
    
    public init(
        row: SQLRow,
        context: SQLContext
    ) throws {
        self.id = try Self.id.textValueRequired(in: row)
        self.make = Self.make.textValue(in: row)
        self.model = Self.model.textValue(in: row)
        self.year = Self.year.longValue(in: row)
        self.fuelType = try Self.fuelType.textValueRequired(in: row)
        self.remoteID = Self.remoteID.textValue(in: row)
        self.syncState = try Self.syncState.textValueRequired(in: row)
    }
    
    public func encode(row: inout SQLRow) throws {
        row[Self.id] = SQLValue(self.id)
        row[Self.make] = SQLValue(self.make)
        row[Self.model] = SQLValue(self.model)
        row[Self.year] = SQLValue(self.year)
        row[Self.fuelType] = SQLValue(self.fuelType)
        row[Self.remoteID] = SQLValue(self.remoteID)
        row[Self.syncState] = SQLValue(self.syncState)
    }
}
