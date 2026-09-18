//
//  VehicleEntityQuery.swift
//  tankful
//
//  Created by Jake Walker on 17/09/2026.
//

import AppIntents

@available(anyAppleOS 26.0, *)
public struct VehicleEntityQuery: EntityQuery {
    public func entities(for identifiers: [VehicleEntity.ID]) async throws -> [VehicleEntity] {
        try await TankfulIntentsEnvironment.vehicleEntities(
            ids: identifiers
        )
    }

    public func suggestedEntities() async throws -> [VehicleEntity] {
        try await TankfulIntentsEnvironment.vehicleEntities()
    }

    public init() {}
}
