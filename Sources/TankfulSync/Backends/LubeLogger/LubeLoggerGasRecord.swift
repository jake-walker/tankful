//
//  LubeLoggerGasRecord.swift
//  tankful
//
//  Created by Jake Walker on 18/09/2026.
//

import Currency
import Foundation
import TankfulDomain

private func makeDateFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}

struct LubeLoggerGasRecord: Codable, Sendable {
    let cost: Decimal
    let date: String
    ///    let endingSoc: Int
    ///    let extraFields: [LubeLoggerExtraFields]
    ///    let files: [...]
    let fuelConsumed: Double
//    let fuelEconomy: Double
    let id: Int64?
    let isFillToFull: Bool
    let missedFuelUp: Bool
    let notes: String?
    let odometer: Int64
//    let startingSoc: Int
//    let tags: String
//    let vehicleId: Int

    init(
        _ fuelLog: FuelLog,
        units: LubeLoggerUnits
    ) {
        if let remoteID = fuelLog.remoteID {
            id = Int64(remoteID)
        } else {
            id = nil
        }

        cost = fuelLog.cost.exactAmount
        date = makeDateFormatter().string(from: fuelLog.date)
        fuelConsumed = fuelLog.volume?.converted(to: units.volume).value ?? 0
        isFillToFull = fuelLog.filled
        missedFuelUp = fuelLog.missedLast
        notes = fuelLog.notes

        if let odometerValue = fuelLog.odometer?.converted(to: units.distance).value {
            odometer = Int64(odometerValue)
        } else {
            odometer = 0
        }
    }

    func toDomain(units: LubeLoggerUnits) throws -> FuelLog {
        guard let id = id else {
            throw LubeLoggerBackend.Error.noRemoteID
        }

        guard let date = makeDateFormatter().date(from: date) else {
            throw LubeLoggerBackend.Error.invalidDate(date: date)
        }

        guard let formattedCost = CurrencyMint.standard.make(identifier: .alphaCode(units.currency.alphabeticCode), exactAmount: cost) else {
            throw LubeLoggerBackend.Error.currencyError
        }

        return FuelLog(
            id: UUID(),
            vehicleID: UUID(),
            date: date,
            odometer: Measurement(value: Double(odometer), unit: units.distance),
            volume: Measurement(value: Double(fuelConsumed), unit: units.volume),
            cost: formattedCost,
            filled: isFillToFull,
            missedLast: missedFuelUp,
            notes: notes,
            remoteID: String(id),
            syncState: .synced
        )
    }
}

struct LubeLoggerGasRecordCreateResponse: Decodable, Sendable {
    let success: Bool
    let message: String
    let additionalData: [String: Int]
}

struct LubeLoggerGasRecordUpdateResponse: Decodable, Sendable {
    let success: Bool
    let message: String
}
