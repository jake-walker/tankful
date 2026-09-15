//
//  TracktorVehicle.swift
//  tankful
//
//  Created by Jake Walker on 16/09/2026.
//

import Foundation
import TankfulDomain

internal struct TracktorVehicle: Codable, Sendable {
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
        self.id = vehicle.remoteID
        self.make = vehicle.make
        self.model = vehicle.model
        self.year = vehicle.year
        self.licensePlate = nil
        self.vin = nil
        self.color = nil
        self.odometer = nil
        self.image = nil
        self.fuelType = vehicle.fuelType.rawValue
        self.vehicleType = "car"
        self.customFields = nil
        self.overallMileage = nil
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
    
    func toDomain() throws -> Vehicle {
        guard let remoteID = self.id else {
            throw TracktorBackend.Error.missingID
        }
        
        return Vehicle(
            id: UUID(),
            make: self.make,
            model: self.model,
            year: self.year,
            fuelType: try Self.parseFuelType(self.fuelType),
            remoteID: remoteID,
            syncState: .synced
        )
    }
}
