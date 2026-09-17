//
//  TankfulIntentsEnvironment.swift
//  tankful
//
//  Created by Jake Walker on 17/09/2026.
//

import TankfulDomain
import TankfulPersistence
import Foundation
import Currency
import CoreSpotlight

@MainActor
public enum TankfulIntentsEnvironment {
    private static var vehicleRepository: (any VehicleRepository)?
    private static var fuelLogRepository: (any FuelLogRepository)?
    private static var openFuelLogHandler: ((FuelLog.ID) -> Void)?
    private static var openVehicleHandler: ((Vehicle.ID) -> Void)?
    
    public static func configure(
        vehicleRepository: any VehicleRepository,
        fuelLogRepository: any FuelLogRepository,
        openFuelLog: ((FuelLog.ID) -> Void)? = nil,
        openVehicle: ((Vehicle.ID) -> Void)? = nil
    ) {
        self.vehicleRepository = vehicleRepository
        self.fuelLogRepository = fuelLogRepository
        self.openFuelLogHandler = openFuelLog
        self.openVehicleHandler = openVehicle
    }
    
    private static func createRepositoriesIfNeeded() throws {
        guard vehicleRepository == nil || fuelLogRepository == nil else {
            return
        }
        
        let directory = URL.applicationSupportDirectory.appendingPathComponent("Tankful", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let databaseURL = directory.appendingPathComponent("Tankful.sqlite")
        
        let database = try TankfulDatabase.live(at: databaseURL)
        
        vehicleRepository = SQLiteVehicleRepository(database: database)
        fuelLogRepository = SQLiteFuelLogRepository(database: database)
    }
}

@available(anyAppleOS 26.0, *)
public extension TankfulIntentsEnvironment {
    static func refreshVehicleIndex() async throws {
        let entities = try await vehicleEntities()
        let index = CSSearchableIndex.default()

        try await index.deleteAppEntities(ofType: VehicleEntity.self)
        try await index.indexAppEntities(entities)
    }
}

@available(anyAppleOS 26.0, *)
internal extension TankfulIntentsEnvironment {
    static func vehicleEntities(ids: [Vehicle.ID]? = nil) async throws -> [VehicleEntity] {
        try createRepositoriesIfNeeded()
        
        guard let vehicleRepository else {
            throw TankfulIntentsError.failedToInitialize
        }
        
        let vehicles = try await vehicleRepository.vehicles()
        
        let requestedIDs = ids.map(Set.init)

        return vehicles
            .filter { requestedIDs?.contains($0.id) ?? true }
            .map(VehicleEntity.init)
    }

    static func fuelLogEntities(ids: [FuelLog.ID]? = nil) async throws -> [FuelLogEntity] {
        try createRepositoriesIfNeeded()

        guard let vehicleRepository, let fuelLogRepository else {
            throw TankfulIntentsError.failedToInitialize
        }

        let requestedIDs = ids.map(Set.init)
        let vehicles = try await vehicleRepository.vehicles()
        let vehicleEntities = Dictionary(uniqueKeysWithValues: vehicles.map { ($0.id, VehicleEntity($0)) })

        return try await fuelLogRepository.fuelLogs()
            .filter { requestedIDs?.contains($0.id) ?? true }
            .sorted { $0.date > $1.date }
            .compactMap { fuelLog in
                guard let vehicle = vehicleEntities[fuelLog.vehicleID] else {
                    return nil
                }

                return FuelLogEntity(fuelLog, vehicle: vehicle)
            }
    }

    static func addFuelLog(
        vehicleID: Vehicle.ID,
        volume: Measurement<UnitVolume>,
        cost: Decimal,
        odometer: Measurement<UnitLength>,
        date: Date
    ) async throws -> FuelLogEntity {
        try createRepositoriesIfNeeded()

        guard let fuelLogRepository else {
            throw TankfulIntentsError.failedToInitialize
        }

        let existingLogs = try await fuelLogRepository.fuelLogs(for: vehicleID)
        let fuelLog = FuelLog(
            id: FuelLog.ID(),
            vehicleID: vehicleID,
            date: date,
            odometer: odometer,
            volume: volume,
            cost: GBP(exactAmount: cost),
            filled: true,
            missedLast: existingLogs.isEmpty,
            syncState: .created
        )

        try await fuelLogRepository.save(fuelLog)

        guard let vehicle = try await vehicleEntities(ids: [vehicleID]).first else {
            throw TankfulIntentsError.failedToInitialize
        }

        return FuelLogEntity(fuelLog, vehicle: vehicle)
    }

    static func latestFuelLog(for vehicle: VehicleEntity) async throws -> FuelLogEntity {
        try createRepositoriesIfNeeded()

        guard let fuelLogRepository else {
            throw TankfulIntentsError.failedToInitialize
        }

        guard let fuelLog = try await fuelLogRepository.fuelLogs(for: vehicle.id)
            .max(by: { $0.date < $1.date }) else {
            throw TankfulIntentsError.noFuelLogs(vehicleName: vehicle.name)
        }

        return FuelLogEntity(fuelLog, vehicle: vehicle)
    }

    static func averageFuelEconomy(for vehicle: VehicleEntity) async throws -> Measurement<UnitFuelEfficiency> {
        try createRepositoriesIfNeeded()

        guard let fuelLogRepository else {
            throw TankfulIntentsError.failedToInitialize
        }

        let calculatedLogs = try await fuelLogRepository.fuelLogs(for: vehicle.id).calculated()
        guard let economy = calculatedLogs.averageFuelEconomy else {
            throw TankfulIntentsError.noFuelEconomy(vehicleName: vehicle.name)
        }

        return economy
    }

    static func openFuelLog(id: FuelLog.ID) throws {
        guard let openFuelLogHandler else {
            throw TankfulIntentsError.unableToOpenFuelLog
        }

        openFuelLogHandler(id)
    }

    static func openVehicle(id: Vehicle.ID) throws {
        guard let openVehicleHandler else {
            throw TankfulIntentsError.unableToOpenVehicle
        }

        openVehicleHandler(id)
    }
}
