//
//  LubeLoggerVehicle.swift
//  tankful
//
//  Created by Jake Walker on 17/09/2026.
//

import Foundation
import TankfulDomain

private let defaultLicensePlatePrefix: String = "TANK-"

private func defaultLicensePlate(for id: UUID) -> String {
    "\(defaultLicensePlatePrefix)-\(id.uuidString.suffix(6).uppercased())"
}

struct LubeLoggerVehicleWrite: Codable, Sendable {
    let id: Int64?
    let year: Int64
    let make: String
    let model: String
    let licensePlate: String
    let fuelType: String
    let extraFields: [LubeLoggerExtraFields]

    init(
        _ vehicle: Vehicle
    ) {
        if let remoteID = vehicle.remoteID {
            id = Int64(remoteID)
        } else {
            id = nil
        }

        // these fields are required by lubelogger, but not by tankful - make up values to satisfy validation
        year = vehicle.year ?? 1900
        make = vehicle.make ?? "Unknown"
        model = vehicle.model ?? "Unknown"
        licensePlate = vehicle.licensePlate ?? defaultLicensePlate(for: vehicle.id)

        switch vehicle.fuelType {
        case .petrol:
            fuelType = "Gasoline"
        case .diesel:
            fuelType = "Diesel"
        }

        if let name = vehicle.name {
            extraFields = [
                .init(name: "name", value: name),
            ]
        } else {
            extraFields = []
        }
    }
}

struct LubeLoggerVehicleRead: Codable, Sendable {
    let extraFields: [LubeLoggerExtraFields]
    ///    let hasOdometerAdjustment: Bool
    let id: Int64
//    let imageLocation: String
    let isDiesel: Bool
    let isElectric: Bool
    let licensePlate: String
    let make: String
//    let mapLocation: String
    let model: String
//    let odometerDifference: Int
//    let odometerMultiplier: Int
//    let odometerOptional: Bool
//    let purchaseDate: String
//    let purchasePrice: Int
//    let soldDate: String
//    let soldPrice: Int
//    let tags: [String]?
//    let useHours: Bool
//    let vehicleIdentifier: String
    let year: Int64

    private var name: String? {
        guard let field = extraFields.first(where: { $0.name == "name" }) else {
            return nil
        }

        return field.value
    }

    func toDomain() throws -> Vehicle {
        var fuelType: FuelType = .petrol

        if isDiesel {
            fuelType = .diesel
        }

        if isElectric {
            throw LubeLoggerBackend.Error.unsupportedFuelType(fuelType: "electric")
        }

        var parsedPlate: String? = nil

        if !licensePlate.isEmpty && !(licensePlate.hasPrefix(defaultLicensePlatePrefix) && licensePlate.count == (defaultLicensePlatePrefix.count + 6)) {
            parsedPlate = licensePlate
        }

        return Vehicle(
            id: UUID(),
            name: name,
            make: make,
            model: model,
            year: year,
            licensePlate: parsedPlate,
            fuelType: fuelType,
            remoteID: String(id),
            syncState: .synced
        )
    }
}

struct LubeLoggerVehicleCreateResponse: Decodable, Sendable {
    let success: Bool
    let message: String
    let additionalData: [String: Int]
}

struct LubeLoggerVehicleUpdateResponse: Decodable, Sendable {
    let success: Bool
    let message: String
}
