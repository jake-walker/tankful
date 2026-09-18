//
//  FuelLogRepository.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

import Foundation

@MainActor
public protocol FuelLogRepository {
    func fuelLog(id: FuelLog.ID) async throws -> FuelLog?
    func fuelLogs() async throws -> [FuelLog]
    func fuelLogs(for vehicleID: Vehicle.ID, startingAt date: Date?) async throws -> [FuelLog]

    func save(_ fuelLog: FuelLog) async throws
    func delete(id: FuelLog.ID) async throws

    func pendingSync() async throws -> [FuelLog]
    func deleteAll() async throws
}

public extension FuelLogRepository {
    func fuelLogs(for vehicleID: Vehicle.ID) async throws -> [FuelLog] {
        try await fuelLogs(for: vehicleID, startingAt: nil)
    }
}
