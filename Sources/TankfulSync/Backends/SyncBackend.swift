//
//  SyncBackend.swift
//  tankful
//
//  Created by Jake Walker on 15/09/2026.
//

import TankfulDomain

@MainActor
public protocol SyncBackend: Sendable {
    func fetchVehicles() async throws -> [Vehicle]
    func fetchFuelLogs(remoteVehicleID: String) async throws -> [FuelLog]

    func createVehicle(_ vehicle: Vehicle) async throws -> String
    func updateVehicle(_ vehicle: Vehicle) async throws
    func deleteVehicle(remoteID: String) async throws

    func createFuelLog(_ log: FuelLog, remoteVehicleID: String) async throws -> String
    func updateFuelLog(_ log: FuelLog, remoteVehicleID: String) async throws
    func deleteFuelLog(remoteID: String, remoteVehicleID: String) async throws
}
