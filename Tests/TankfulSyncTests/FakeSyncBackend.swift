//
//  FakeSyncBackend.swift
//  tankful
//
//  Created by Jake Walker on 04/11/2026.
//

import TankfulDomain
import TankfulSync

final class FakeSyncBackend: SyncBackend {
    enum Error: Swift.Error {
        case vehicleNotFound
        case fuelLogNotFound
        case intentionalFailure
    }

    private var nextVehicleID: Int
    private var nextFuelLogID: Int

    var vehicles: [Vehicle]
    var fuelLogs: [FuelLog]

    var callLog: [BackendCall]

    var fetchFuelLogsError: (any Swift.Error)?

    init(vehicles: [Vehicle] = [], fuelLogs: [FuelLog] = []) {
        self.vehicles = vehicles
        self.fuelLogs = fuelLogs
        callLog = []
        nextVehicleID = (vehicles.compactMap { $0.remoteID.flatMap(Int.init) }.max() ?? -1) + 1
        nextFuelLogID = (fuelLogs.compactMap { $0.remoteID.flatMap(Int.init) }.max() ?? -1) + 1
    }

    func fetchVehicles() async throws -> [Vehicle] {
        callLog.append(.fetchVehicles)

        return vehicles
    }

    func fetchFuelLogs(remoteVehicleID: String) async throws -> [FuelLog] {
        callLog.append(.fetchFuelLogs)

        if let fetchFuelLogsError {
            throw fetchFuelLogsError
        }

        guard let vehicle = vehicles.first(where: { $0.remoteID == remoteVehicleID }) else {
            throw Error.vehicleNotFound
        }
        return fuelLogs.filter { $0.vehicleID == vehicle.id }
    }

    func createVehicle(_ vehicle: Vehicle) async throws -> String {
        callLog.append(.createVehicle(vehicle))

        while vehicles.contains(where: { $0.remoteID == String(nextVehicleID) }) {
            nextVehicleID += 1
        }
        let remoteID = String(nextVehicleID)
        nextVehicleID += 1

        var storedVehicle = vehicle
        storedVehicle.remoteID = remoteID
        storedVehicle.syncState = .synced
        vehicles.append(storedVehicle)

        return remoteID
    }

    func updateVehicle(_ vehicle: Vehicle) async throws {
        callLog.append(.updateVehicle(vehicle))

        guard let remoteID = vehicle.remoteID,
              let index = vehicles.firstIndex(where: { $0.remoteID == remoteID })
        else {
            throw Error.vehicleNotFound
        }
        var storedVehicle = vehicle.with(id: vehicles[index].id)
        storedVehicle.syncState = .synced
        vehicles[index] = storedVehicle
    }

    func deleteVehicle(remoteID _: String) async throws {
        fatalError("Not implemented")
    }

    func createFuelLog(_ log: FuelLog, remoteVehicleID: String) async throws -> String {
        callLog.append(.createFuelLog(log, remoteVehicleID: remoteVehicleID))

        guard let vehicle = vehicles.first(where: { $0.remoteID == remoteVehicleID }) else {
            throw Error.vehicleNotFound
        }
        while fuelLogs.contains(where: { $0.remoteID == String(nextFuelLogID) }) {
            nextFuelLogID += 1
        }
        let remoteID = String(nextFuelLogID)
        nextFuelLogID += 1

        var storedLog = log
        storedLog.vehicleID = vehicle.id
        storedLog.remoteID = remoteID
        storedLog.syncState = .synced
        fuelLogs.append(storedLog)

        return remoteID
    }

    func updateFuelLog(_ log: FuelLog, remoteVehicleID: String) async throws {
        callLog.append(.updateFuelLog(log, remoteVehicleID: remoteVehicleID))

        guard let vehicle = vehicles.first(where: { $0.remoteID == remoteVehicleID }) else {
            throw Error.vehicleNotFound
        }
        guard let remoteID = log.remoteID,
              let index = fuelLogs.firstIndex(where: {
                  $0.remoteID == remoteID && $0.vehicleID == vehicle.id
              })
        else {
            throw Error.fuelLogNotFound
        }
        var storedLog = log.with(id: fuelLogs[index].id, vehicleID: vehicle.id)
        storedLog.syncState = .synced
        fuelLogs[index] = storedLog
    }

    func deleteFuelLog(remoteID _: String, remoteVehicleID _: String) async throws {
        fatalError("Not implemented")
    }
}

enum BackendCall: Equatable {
    case createVehicle(Vehicle)
    case updateVehicle(Vehicle)
    case fetchVehicles
    case createFuelLog(FuelLog, remoteVehicleID: String)
    case updateFuelLog(FuelLog, remoteVehicleID: String)
    case fetchFuelLogs
}
