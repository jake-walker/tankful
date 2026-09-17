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
            name: vehicle.name,
            make: vehicle.make,
            model: vehicle.model,
            year: vehicle.year,
            fuelType: vehicle.fuelType.rawValue,
            remoteID: vehicle.remoteID,
            syncState: vehicle.syncState.rawValue
        )
    }
    
    func toDomain() throws -> Vehicle {
        guard let uuid = UUID(uuidString: self.id) else {
            throw PersistenceMappingError.invalidUUID
        }
        
        return Vehicle(
            id: uuid,
            name: self.name,
            make: self.make,
            model: self.model,
            year: self.year,
            fuelType: try decodeEnum(FuelType.self, from: self.fuelType),
            remoteID: self.remoteID,
            syncState: try decodeEnum(SyncState.self, from: self.syncState)
        )
    }
}
