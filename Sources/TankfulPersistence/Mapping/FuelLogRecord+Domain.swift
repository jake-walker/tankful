//
//  FuelLogRecord+Domain.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

import Foundation
import TankfulDomain
import Currency

extension FuelLogRecord {
    init(_ fuelLog: FuelLog) throws {
        self.init(
            id: fuelLog.id.uuidString,
            vehicleID: fuelLog.vehicleID.uuidString,
            date: Int64(fuelLog.date.timeIntervalSince1970),
            odometerMetres: fuelLog.odometer.map { Int64($0.converted(to: .meters).value) },
            volumeLitres: fuelLog.volume?.converted(to: .liters).value,
            costMinorUnits: fuelLog.cost.minorUnits,
            currencyCode: fuelLog.cost.descriptor.alphabeticCode,
            filled: fuelLog.filled ? 1 : 0,
            missedLast: fuelLog.missedLast ? 1 : 0,
            notes: fuelLog.notes,
            remoteID: fuelLog.remoteID,
            syncState: fuelLog.syncState.rawValue
        )
    }
    
    func toDomain() throws -> FuelLog {
        guard let uuid = UUID(uuidString: self.id),
              let vehicleUUID = UUID(uuidString: self.vehicleID) else {
            throw PersistenceMappingError.invalidUUID
        }
        
        guard let cost = CurrencyMint.standard.make(identifier: .init(self.currencyCode), minorUnits: self.costMinorUnits) else {
            throw PersistenceMappingError.invalidEnumValue(type: CurrencyMint.CurrencyIdentifier.self, value: self.currencyCode)
        }
        
        return FuelLog(
            id: uuid,
            vehicleID: vehicleUUID,
            date: Date(timeIntervalSince1970: TimeInterval(self.date)),
            odometer: self.odometerMetres.map { Measurement(value: Double($0), unit: UnitLength.meters) },
            volume: self.volumeLitres.map { Measurement(value: $0, unit: UnitVolume.liters) },
            cost: cost,
            filled: self.filled == 1,
            missedLast: self.missedLast == 1,
            notes: self.notes,
            remoteID: self.remoteID,
            syncState: try decodeEnum(SyncState.self, from: self.syncState)
        )
    }
}
