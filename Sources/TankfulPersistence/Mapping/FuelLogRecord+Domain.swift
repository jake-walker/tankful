//
//  FuelLogRecord+Domain.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

import Currency
import Foundation
import TankfulDomain

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
        guard let uuid = UUID(uuidString: id),
              let vehicleUUID = UUID(uuidString: vehicleID)
        else {
            throw PersistenceMappingError.invalidUUID
        }

        guard let cost = CurrencyMint.standard.make(identifier: .init(currencyCode), minorUnits: costMinorUnits) else {
            throw PersistenceMappingError.invalidEnumValue(type: CurrencyMint.CurrencyIdentifier.self, value: currencyCode)
        }

        return try FuelLog(
            id: uuid,
            vehicleID: vehicleUUID,
            date: Date(timeIntervalSince1970: TimeInterval(date)),
            odometer: odometerMetres.map { Measurement(value: Double($0), unit: UnitLength.meters) },
            volume: volumeLitres.map { Measurement(value: $0, unit: UnitVolume.liters) },
            cost: cost,
            filled: filled == 1,
            missedLast: missedLast == 1,
            notes: notes,
            remoteID: remoteID,
            syncState: decodeEnum(SyncState.self, from: syncState)
        )
    }
}
