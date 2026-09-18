//
//  VehicleRepository.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

@MainActor
public protocol VehicleRepository {
    func vehicle(id: Vehicle.ID) async throws -> Vehicle?
    func vehicles() async throws -> [Vehicle]

    func save(_ vehicle: Vehicle) async throws
    func delete(id: Vehicle.ID) async throws

    func pendingSync() async throws -> [Vehicle]
    func deleteAll() async throws
}
