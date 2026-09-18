//
//  FuelLog.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

import Currency
import Foundation

public struct FuelLog: Identifiable {
    public var id: UUID
    public var vehicleID: Vehicle.ID
    public var date: Date
    public var odometer: Measurement<UnitLength>?
    public var volume: Measurement<UnitVolume>?
    public var cost: any CurrencyValue
    public var filled: Bool
    public var missedLast: Bool
    public var notes: String?

    public var remoteID: String?
    public var syncState: SyncState

    public init(id: UUID, vehicleID: Vehicle.ID, date: Date, odometer: Measurement<UnitLength>? = nil, volume: Measurement<UnitVolume>? = nil, cost: any CurrencyValue, filled: Bool, missedLast: Bool, notes: String? = nil, remoteID: String? = nil, syncState: SyncState = .synced) {
        self.id = id
        self.vehicleID = vehicleID
        self.date = date
        self.odometer = odometer
        self.volume = volume
        self.cost = cost
        self.filled = filled
        self.missedLast = missedLast
        self.notes = notes
        self.remoteID = remoteID
        self.syncState = syncState
    }

    public var unitCost: any CurrencyValue? {
        guard let volume else {
            return nil
        }

        var unitCost = cost
        unitCost.divide(by: Decimal(volume.converted(to: .liters).value))
        return unitCost
    }

    public func with(id newUUID: UUID, vehicleID: UUID) -> Self {
        .init(id: newUUID, vehicleID: vehicleID, date: date, odometer: odometer, volume: volume, cost: cost, filled: filled, missedLast: missedLast, notes: notes, remoteID: remoteID, syncState: syncState)
    }
}
