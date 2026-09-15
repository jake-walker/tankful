//
//  VehicleRecord+Domain.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

import Foundation
import TankfulDomain

extension VehicleRecord {
    init(_ vehicle: Vehicle) throws {
        self.init(
            id: vehicle.id.uuidString,
            make: vehicle.make,
            model: vehicle.model,
            year: vehicle.year,
            fuelType: vehicle.fuelType.rawValue
        )
    }
    
    func toDomain() throws -> Vehicle {
        guard let uuid = UUID(uuidString: self.id) else {
            throw PersistenceMappingError.invalidUUID
        }
        
        return Vehicle(
            id: uuid,
            make: self.make,
            model: self.model,
            year: self.year,
            fuelType: try decodeEnum(FuelType.self, from: self.fuelType)
        )
    }
}
