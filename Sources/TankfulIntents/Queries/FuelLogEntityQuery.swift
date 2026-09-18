import AppIntents

@available(anyAppleOS 26.0, *)
public struct FuelLogEntityQuery: EntityQuery {
    public func entities(for identifiers: [FuelLogEntity.ID]) async throws -> [FuelLogEntity] {
        try await TankfulIntentsEnvironment.fuelLogEntities(ids: identifiers)
    }

    public func suggestedEntities() async throws -> [FuelLogEntity] {
        let entities = try await TankfulIntentsEnvironment.fuelLogEntities()
        return Array(entities.prefix(20))
    }

    public init() {}
}

//  FuelLogEntityQuery.swift
//  tankful
//
//  Created by Jake Walker on 17/09/2026.
//
