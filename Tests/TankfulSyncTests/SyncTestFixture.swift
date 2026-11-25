//
//  SyncTestFixture.swift
//  tankful
//
//  Created by Jake Walker on 04/11/2026.
//

import Foundation
import TankfulDomain
import TankfulPersistence
import TankfulSync

struct SyncTestFixture {
    let database: TankfulDatabase
    let vehicleRepository: SQLiteVehicleRepository
    let fuelLogRepository: SQLiteFuelLogRepository
    let backend: FakeSyncBackend
    let engine: SyncEngine

    @MainActor
    static func make(
        localVehicles initialVehicles: [Vehicle] = [],
        localFuelLogs initialFuelLogs: [FuelLog] = [],
        remoteVehicles: [Vehicle] = [],
        remoteFuelLogs: [FuelLog] = [],
        lastSuccessfulSync: Date? = nil
    ) async throws -> SyncTestFixture {
        let db = try TankfulDatabase.inMemory()

        let vehicles = SQLiteVehicleRepository(database: db)
        let fuelLogs = SQLiteFuelLogRepository(database: db)

        for vehicle in initialVehicles {
            try vehicles.save(vehicle)
        }
        for fuelLog in initialFuelLogs {
            try fuelLogs.save(fuelLog)
        }

        let backend = FakeSyncBackend(vehicles: remoteVehicles, fuelLogs: remoteFuelLogs)

        let engine = SyncEngine(
            backend: backend,
            vehicleRepository: vehicles,
            fuelLogRepository: fuelLogs,
            snapshotRepository: SQLiteSyncSnapshotRepository(database: db),
            lastSuccessfulSync: lastSuccessfulSync
        )

        return SyncTestFixture(
            database: db,
            vehicleRepository: vehicles,
            fuelLogRepository: fuelLogs,
            backend: backend,
            engine: engine
        )
    }
}
