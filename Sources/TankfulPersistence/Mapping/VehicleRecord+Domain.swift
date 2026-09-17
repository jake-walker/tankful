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
            licensePlate: vehicle.licensePlate,
            fuelType: vehicle.fuelType.rawValue,
            remoteID: vehicle.remoteID,
            syncState: vehicle.syncState.rawValue
        )
    }

    func toDomain() throws -> Vehicle {
        guard let uuid = UUID(uuidString: id) else {
            throw PersistenceMappingError.invalidUUID
        }

        return try Vehicle(
            id: uuid,
            name: name,
            make: make,
            model: model,
            year: year,
            licensePlate: licensePlate,
            fuelType: decodeEnum(FuelType.self, from: fuelType),
            remoteID: remoteID,
            syncState: decodeEnum(SyncState.self, from: syncState)
        )
    }
}
