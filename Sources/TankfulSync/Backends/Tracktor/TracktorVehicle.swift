//
//  TracktorVehicle.swift
//  tankful
//
//  Created by Jake Walker on 16/09/2026.
//

import Foundation
import TankfulDomain

private let tracktorNameKey: String = "name"

struct TracktorVehicle: Codable, Sendable {
    let id: String?
    let make: String?
    let model: String?
    let year: Int64?
    let licensePlate: String?
    let vin: String?
    let color: String?
    let odometer: Int?
    let image: String?
    let fuelType: String
    let vehicleType: String
    let customFields: [String: String]?
    let overallMileage: Double?

    enum CodingKeys: String, CodingKey {
        case id, make, model, year, licensePlate, vin, color, odometer, image, fuelType, vehicleType, customFields, overallMileage
    }

    init(
        _ vehicle: Vehicle
    ) {
        id = vehicle.remoteID
        make = vehicle.make
        model = vehicle.model
        year = vehicle.year
        licensePlate = vehicle.licensePlate
        vin = nil
        color = nil
        odometer = nil
        image = nil
        fuelType = vehicle.fuelType.rawValue
        vehicleType = "car"
        overallMileage = nil

        if let name = vehicle.name {
            customFields = [tracktorNameKey: name]
        } else {
            customFields = nil
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(make, forKey: .make)
        try container.encode(model, forKey: .model)
        try container.encode(year, forKey: .year)
        try container.encode(licensePlate, forKey: .licensePlate)
        try container.encode(vin, forKey: .vin)
        try container.encode(color, forKey: .color)
        try container.encode(odometer, forKey: .odometer)
        try container.encode(image, forKey: .image)
        try container.encode(fuelType, forKey: .fuelType)
        try container.encode(vehicleType, forKey: .vehicleType)
        try container.encode(customFields, forKey: .customFields)

        // Create schema does not include this key, but update schema accepts it
        if id != nil {
            try container.encode(overallMileage, forKey: .overallMileage)
        }
    }
}

extension TracktorVehicle {
    private static func parseFuelType(_ input: String) throws -> FuelType {
        switch input {
        case "petrol": return .petrol
        case "diesel": return .diesel
        case let value: throw TracktorBackend.Error.unsupportedFuelType(fuelType: value)
        }
    }

    private var name: String? {
        guard let name = customFields?[tracktorNameKey] else {
            return nil
        }

        return name
    }

    func toDomain() throws -> Vehicle {
        guard let remoteID = id else {
            throw TracktorBackend.Error.missingID
        }

        return try Vehicle(
            id: UUID(),
            name: name,
            make: make,
            model: model,
            year: year,
            licensePlate: licensePlate,
            fuelType: Self.parseFuelType(fuelType),
            remoteID: remoteID,
            syncState: .synced
        )
    }
}
