//
//  LubeLoggerBackend.swift
//  tankful
//
//  Created by Jake Walker on 17/09/2026.
//

import Foundation
import TankfulDomain

@MainActor
public final class LubeLoggerBackend: SyncBackend {
    public enum Error: Swift.Error, Equatable, Sendable, LocalizedError {
        case noRemoteID
        case invalidDate(date: String)
        case currencyError
        case unsupportedFuelType(fuelType: String)
        case badResponse

        public var errorDescription: String? {
            switch self {
            case .noRemoteID:
                NSLocalizedString("Local entity is missing remote ID", comment: "LubeLogger sync error")
            case let .invalidDate(date):
                String(
                    format: NSLocalizedString("Failed to parse date %@", comment: "LubeLogger sync error; argument is a date string"),
                    date
                )
            case .currencyError:
                NSLocalizedString("Failed to create currency", comment: "LubeLogger sync error")
            case let .unsupportedFuelType(fuelType):
                String(
                    format: NSLocalizedString("Unsupported fuel type %@", comment: "LubeLogger sync error; argument is a fuel type"),
                    fuelType
                )
            case .badResponse:
                NSLocalizedString("Request to LubeLogger was unsuccessful", comment: "LubeLogger sync error")
            }
        }
    }

    private let client: HTTPClient
    private var units: LubeLoggerUnits

    public init(
        client: HTTPClient,
        units: LubeLoggerUnits
    ) {
        self.client = client
        self.units = units
    }

    public func fetchVehicles() async throws -> [Vehicle] {
        let response: [LubeLoggerVehicleRead] = try await client.request(
            .get,
            path: "/api/vehicles",
            headers: ["culture-invariant": "yes"]
        )

        return try response
            .map { try $0.toDomain() }
    }

    public func fetchFuelLogs(remoteVehicleID: String) async throws -> [FuelLog] {
        let response: [LubeLoggerGasRecord] = try await client.request(
            .get,
            path: "/api/vehicle/gasrecords",
            query: [.init(name: "vehicleId", value: remoteVehicleID)],
            headers: ["culture-invariant": "yes"]
        )

        return try response
            .map { try $0.toDomain(units: self.units) }
    }

    public func createVehicle(_ vehicle: Vehicle) async throws -> String {
        var vehicle = vehicle

        if vehicle.remoteID != nil {
            vehicle.remoteID = nil
        }

        let response: LubeLoggerVehicleCreateResponse = try await client.request(
            .post,
            path: "/api/vehicles/add",
            headers: ["culture-invariant": "yes"],
            body: LubeLoggerVehicleWrite(vehicle)
        )

        guard response.success,
              let vehicleID = response.additionalData["vehicleId"]
        else {
            throw Error.badResponse
        }

        return String(vehicleID)
    }

    public func updateVehicle(_ vehicle: Vehicle) async throws {
        guard vehicle.remoteID != nil else {
            throw LubeLoggerBackend.Error.noRemoteID
        }

        let response: LubeLoggerVehicleUpdateResponse = try await client.request(
            .put,
            path: "/api/vehicles/update",
            headers: ["culture-invariant": "yes"],
            body: LubeLoggerVehicleWrite(vehicle)
        )

        guard response.success else {
            throw Error.badResponse
        }
    }

    public func deleteVehicle(remoteID: String) async throws {
        let response: LubeLoggerVehicleUpdateResponse = try await client.request(
            .delete,
            path: "/api/vehicles/delete",
            headers: ["culture-invariant": "yes"],
            body: ["id": Int64(remoteID)]
        )

        guard response.success else {
            throw Error.badResponse
        }
    }

    public func createFuelLog(_ log: FuelLog, remoteVehicleID: String) async throws -> String {
        var log = log

        if log.remoteID != nil {
            log.remoteID = nil
        }

        let response: LubeLoggerGasRecordCreateResponse = try await client.request(
            .post,
            path: "/api/vehicle/gasrecords/add",
            query: [.init(name: "vehicleId", value: remoteVehicleID)],
            headers: ["culture-invariant": "yes"],
            body: LubeLoggerGasRecord(log, units: units)
        )

        guard response.success,
              let recordID = response.additionalData["recordId"]
        else {
            throw Error.badResponse
        }

        return String(recordID)
    }

    public func updateFuelLog(_ log: FuelLog, remoteVehicleID _: String) async throws {
        guard log.remoteID != nil else {
            throw LubeLoggerBackend.Error.noRemoteID
        }

        let response: LubeLoggerGasRecordUpdateResponse = try await client.request(
            .put,
            path: "/api/vehicle/gasrecords/update",
            headers: ["culture-invariant": "yes"],
            body: LubeLoggerGasRecord(log, units: units)
        )

        guard response.success else {
            throw Error.badResponse
        }
    }

    public func deleteFuelLog(remoteID: String, remoteVehicleID _: String) async throws {
        let response: LubeLoggerVehicleUpdateResponse = try await client.request(
            .delete,
            path: "/api/vehicle/gasrecords/delete",
            headers: ["culture-invariant": "yes"],
            body: ["id": Int64(remoteID)]
        )

        guard response.success else {
            throw Error.badResponse
        }
    }
}
