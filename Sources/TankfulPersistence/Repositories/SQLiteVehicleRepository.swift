//
//  SQLiteVehicleRepository.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

import SkipSQLCore
import TankfulDomain

public final class SQLiteVehicleRepository: VehicleRepository {
    private let database: TankfulDatabase

    public init(database: TankfulDatabase) {
        self.database = database
    }

    public func vehicle(id: Vehicle.ID) async throws -> Vehicle? {
        return try database.ctx.fetch(VehicleRecord.self, id: SQLValue(id.uuidString))?
            .toDomain()
    }

    public func vehicles() async throws -> [Vehicle] {
        return try database.ctx.fetchAll(VehicleRecord.self)
            .map { try $0.toDomain() }
    }

    public func save(_ vehicle: Vehicle) throws {
        try database.ctx.insert(VehicleRecord(vehicle), upsert: true)
    }

    public func delete(id: Vehicle.ID) async throws {
        let vehicleID = SQLValue(id.uuidString)
        let fuelLogPredicate = FuelLogRecord.vehicleID.equals(vehicleID)
        try database.ctx.delete(FuelLogRecord.self, where: fuelLogPredicate)

        let vehiclePredicate = VehicleRecord.id.equals(vehicleID)
        try database.ctx.delete(VehicleRecord.self, where: vehiclePredicate)
    }

    public func pendingSync() async throws -> [Vehicle] {
        let predicate = VehicleRecord.syncState.notEquals(SQLValue(SyncState.synced.rawValue))
        return try database.ctx.fetchAll(VehicleRecord.self, where: predicate)
            .map { try $0.toDomain() }
    }

    public func deleteAll() async throws {
        try database.ctx.deleteAll(VehicleRecord.self)
    }
}
