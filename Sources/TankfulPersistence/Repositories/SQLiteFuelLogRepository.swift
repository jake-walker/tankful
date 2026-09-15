//
//  SQLiteFuelLogRepository.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

import TankfulDomain
import SkipSQLCore

public final class SQLiteFuelLogRepository: FuelLogRepository {
    private let database: TankfulDatabase
    
    public init(database: TankfulDatabase) {
        self.database = database
    }
    
    public func fuelLog(id: FuelLog.ID) async throws -> FuelLog? {
        return try database.ctx.fetch(FuelLogRecord.self, id: SQLValue(id.uuidString))?
            .toDomain()
    }
    
    public func fuelLogs() async throws -> [FuelLog] {
        return try database.ctx.fetchAll(FuelLogRecord.self)
            .map { try $0.toDomain() }
    }
    
    public func fuelLogs(for vehicleID: Vehicle.ID) async throws -> [FuelLog] {
        let predicate = FuelLogRecord.vehicleID.equals(SQLValue(vehicleID.uuidString))
        return try database.ctx.fetchAll(FuelLogRecord.self, where: predicate)
            .map { try $0.toDomain() }
    }
    
    public func save(_ fuelLog: FuelLog) throws {
        try database.ctx.insert(FuelLogRecord(fuelLog), upsert: true)
    }
    
    public func delete(id: FuelLog.ID) async throws {
        let predicate = FuelLogRecord.id.equals(SQLValue(id.uuidString))
        try database.ctx.delete(FuelLogRecord.self, where: predicate)
    }
    
    public func pendingSync() async throws -> [FuelLog] {
        let predicate = FuelLogRecord.syncState.notEquals(SQLValue(SyncState.synced.rawValue))
        return try database.ctx.fetchAll(FuelLogRecord.self, where: predicate)
            .map { try $0.toDomain() }
    }
    
    public func deleteAll() async throws {
        try database.ctx.deleteAll(FuelLogRecord.self)
    }
}
