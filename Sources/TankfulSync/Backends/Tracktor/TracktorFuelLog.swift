//
//  TracktorFuelLog.swift
//  tankful
//
//  Created by Jake Walker on 16/09/2026.
//

import Currency
import Foundation
import TankfulDomain

struct TracktorFuelLog: Codable, Sendable {
    let id: String?
    let vehicleID: String
    let date: String
    let odometer: Int?
    let filled: Bool
    let missedLast: Bool
    let fuelAmount: Double?
    let rate: Double?
    let cost: Decimal
    let notes: String?
    let attachment: String?

    enum CodingKeys: String, CodingKey {
        case id
        case vehicleID = "vehicleId"
        case date
        case odometer
        case filled
        case missedLast
        case fuelAmount
        case rate
        case cost
        case notes
        case attachment
    }

    init(
        _ log: FuelLog,
        remoteUnits: TracktorUnits,
        remoteVehicleID: String
    ) throws {
        guard remoteUnits.currency.uppercased() == log.cost.descriptor.alphabeticCode.uppercased() else {
            throw TracktorBackend.Error.currencyMismatch(logCurrency: log.cost.descriptor.alphabeticCode, remoteCurrency: remoteUnits.currency)
        }

        id = log.remoteID
        vehicleID = remoteVehicleID
        date = log.date.ISO8601Format(.iso8601(timeZone: .gmt, includingFractionalSeconds: true))
        odometer = log.odometer.map { Int($0.converted(to: remoteUnits.distance).value.rounded()) }
        filled = log.filled
        missedLast = log.missedLast
        fuelAmount = log.volume?.converted(to: remoteUnits.volume).value
        rate = log.unitCost.map { NSDecimalNumber(decimal: $0.exactAmount).doubleValue }
        cost = log.cost.exactAmount
        notes = log.notes
        attachment = nil
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(vehicleID, forKey: .vehicleID)
        try container.encode(date, forKey: .date)
        try container.encode(odometer, forKey: .odometer)
        try container.encode(filled, forKey: .filled)
        try container.encode(missedLast, forKey: .missedLast)
        try container.encode(fuelAmount, forKey: .fuelAmount)
        try container.encode(rate, forKey: .rate)
        try container.encode(cost, forKey: .cost)
        try container.encode(notes, forKey: .notes)
        try container.encode(attachment, forKey: .attachment)
    }
}

extension TracktorFuelLog {
    private static func parseDate(_ value: String) -> Date? {
        let calendar = Calendar(identifier: .iso8601)
        let timeZone = TimeZone(secondsFromGMT: 0)!

        // ISO 8601 timestamp
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds,
        ]

        var date = isoFormatter.date(from: value)

        // try ISO 8601 without fractional seconds
        if date == nil {
            isoFormatter.formatOptions = [
                .withInternetDateTime,
            ]

            date = isoFormatter.date(from: value)
        }

        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd",
        ]

        for format in formats {
            if date == nil {
                let formatter = DateFormatter()
                formatter.calendar = calendar
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = timeZone
                formatter.dateFormat = format

                date = formatter.date(from: value)
            } else {
                break
            }
        }

        guard let date else {
            return nil
        }

        var utcCalendar = calendar
        utcCalendar.timeZone = timeZone

        return utcCalendar.startOfDay(for: date)
    }

    func toDomain(units: TracktorUnits) throws -> FuelLog {
        guard let remoteID = id else {
            throw TracktorBackend.Error.missingID
        }

        guard let date = Self.parseDate(date) else {
            throw TracktorBackend.Error.invalidDate(date: date)
        }

        guard let cost = CurrencyMint.standard.make(
            identifier: .alphaCode(units.currency),
            exactAmount: cost
        ) else {
            throw TracktorBackend.Error.unsupportedCurrency(currencyCode: units.currency)
        }

        return FuelLog(
            id: UUID(),
            vehicleID: UUID(),
            date: date,
            odometer: odometer.map {
                Measurement(value: Double($0), unit: units.distance)
            },
            volume: fuelAmount.map {
                Measurement(value: $0, unit: units.volume)
            },
            cost: cost,
            filled: filled,
            missedLast: missedLast,
            notes: notes,
            remoteID: remoteID,
            syncState: .synced
        )
    }
}
