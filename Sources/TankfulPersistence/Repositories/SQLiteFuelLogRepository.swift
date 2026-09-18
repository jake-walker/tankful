//
//  SQLiteFuelLogRepository.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

import Foundation
import SkipSQLCore
import TankfulDomain

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

    public func fuelLogs(for vehicleID: Vehicle.ID, startingAt date: Date?) async throws -> [FuelLog] {
        var predicate = FuelLogRecord.vehicleID.equals(SQLValue(vehicleID.uuidString))

        if let date {
            predicate = predicate.and(
                FuelLogRecord.date.greaterThanOrEqual(
                    SQLValue(Int64(date.timeIntervalSince1970.rounded(.up)))
                )
            )
        }

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
