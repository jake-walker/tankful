//
//  VehicleController.swift
//  tankful
//
//  Created by Jake Walker on 16/09/2026.
//

import TankfulDomain

@MainActor
final class VehicleController {
    private let repository: any VehicleRepository

    init(repository: any VehicleRepository) {
        self.repository = repository
    }

    func create(_ vehicle: Vehicle) async throws {
        var vehicle = vehicle
        vehicle.syncState = .created

        try await repository.save(vehicle)
    }

    func update(_ vehicle: Vehicle) async throws {
        var vehicle = vehicle

        if vehicle.syncState != .created {
            vehicle.syncState = .modified
        }

        try await repository.save(vehicle)
    }
}
