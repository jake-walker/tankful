//
//  CalculatedFuelLog.swift
//  tankful
//
//  Created by Jake Walker on 15/09/2026.
//

import Currency
import Foundation

public struct CalculatedFuelLog: Identifiable {
    public let log: FuelLog
    public let distance: Measurement<UnitLength>?
    fileprivate let economyVolume: Measurement<UnitVolume>?

    public var id: FuelLog.ID {
        log.id
    }

    public var economy: Measurement<UnitFuelEfficiency>? {
        guard log.filled,
              !log.missedLast,
              let distance,
              let economyVolume
        else {
            return nil
        }

        return calculateFuelEconomy(distance: distance, volume: economyVolume)
    }

    public func costPerDistance(unit: UnitLength) -> (any CurrencyValue)? {
        guard let distance else {
            return nil
        }

        let distanceConverted = distance.converted(to: unit).value

        guard distanceConverted > 0 else {
            return nil
        }

        return CurrencyMint.standard.make(
            identifier: .alphaCode(log.cost.descriptor.alphabeticCode),
            exactAmount: log.cost.exactAmount / Decimal(distanceConverted)
        )
    }

    public init(log: FuelLog, distance: Measurement<UnitLength>?) {
        self.log = log
        self.distance = distance
        economyVolume = log.volume
    }

    fileprivate init(
        log: FuelLog,
        distance: Measurement<UnitLength>?,
        economyVolume: Measurement<UnitVolume>?
    ) {
        self.log = log
        self.distance = distance
        self.economyVolume = economyVolume
    }
}

extension Array where Element == FuelLog {
    private func calculateDistance(from previous: FuelLog, to current: FuelLog) -> Measurement<UnitLength>? {
        guard let previousOdometer = previous.odometer,
              let currentOdometer = current.odometer
        else {
            return nil
        }

        let previous = previousOdometer.converted(to: currentOdometer.unit)

        guard currentOdometer.value >= previous.value else {
            return nil
        }

        return Measurement(
            value: currentOdometer.value - previous.value,
            unit: currentOdometer.unit
        )
    }

    public func calculated() -> [CalculatedFuelLog] {
        let sortedLogs = sorted { $0.date < $1.date }
        var calculatedLogs: [CalculatedFuelLog] = []
        var previousLog: FuelLog?
        var previousFilledLog: FuelLog?
        var accumulatedVolume = Measurement(value: 0, unit: UnitVolume.liters)
        var intervalIsComplete = true

        for log in sortedLogs {
            let adjacentDistance = previousLog.flatMap {
                calculateDistance(from: $0, to: log)
            }

            if log.missedLast || log.volume == nil {
                intervalIsComplete = false
            } else if let volume = log.volume {
                accumulatedVolume = accumulatedVolume + volume.converted(to: .liters)
            }

            let distance: Measurement<UnitLength>?
            let economyVolume: Measurement<UnitVolume>?

            if log.filled {
                if intervalIsComplete, let previousFilledLog {
                    distance = calculateDistance(from: previousFilledLog, to: log)
                    economyVolume = distance == nil ? nil : accumulatedVolume
                } else {
                    distance = nil
                    economyVolume = nil
                }
            } else {
                distance = adjacentDistance
                economyVolume = nil
            }

            calculatedLogs.append(CalculatedFuelLog(
                log: log,
                distance: distance,
                economyVolume: economyVolume
            ))

            if log.filled {
                previousFilledLog = log.odometer == nil ? nil : log
                accumulatedVolume = Measurement(value: 0, unit: .liters)
                intervalIsComplete = true
            }

            previousLog = log
        }

        // reverse the list so newest entries are first
        var newestFirst: [CalculatedFuelLog] = []
        var index = calculatedLogs.count

        while index > 0 {
            index -= 1
            newestFirst.append(calculatedLogs[index])
        }

        return newestFirst
    }
}

public extension Collection where Element == CalculatedFuelLog {
    var totalDistance: Measurement<UnitLength> {
        let metres = compactMap(\.distance)
            .reduce(0) {
                $0 + $1.converted(to: .meters).value
            }

        return Measurement(value: metres, unit: .meters)
    }

    var totalVolume: Measurement<UnitVolume> {
        let litres = compactMap(\.log.volume)
            .reduce(0) {
                $0 + $1.converted(to: .liters).value
            }

        return Measurement(value: litres, unit: .liters)
    }

    var averageFuelEconomy: Measurement<UnitFuelEfficiency>? {
        let validLogs = filter { $0.economy != nil }

        let distance = validLogs.compactMap(\.distance)
            .reduce(0) {
                $0 + $1.converted(to: .meters).value
            }

        let volume = validLogs.compactMap(\.economyVolume)
            .reduce(0) {
                $0 + $1.converted(to: .liters).value
            }

        guard distance > 0, volume > 0 else {
            return nil
        }

        return calculateFuelEconomy(
            distance: Measurement(value: distance, unit: .meters),
            volume: Measurement(value: volume, unit: .liters)
        )
    }

    func averageCostPerDistance(unit: UnitLength) -> (any CurrencyValue)? {
        let logs = filter {
            !$0.log.missedLast && $0.distance != nil
        }

        guard let currency = logs.first?.log.cost.descriptor.alphabeticCode,
              logs.allSatisfy({ $0.log.cost.descriptor.alphabeticCode == currency })
        else {
            return nil
        }

        let totalCost = logs.compactMap(\.log.cost)
            .reduce(Decimal.zero) {
                $0 + $1.exactAmount
            }

        let totalDistance = logs.compactMap(\.distance)
            .reduce(0) {
                $0 + $1.converted(to: unit).value
            }

        guard totalDistance > 0 else {
            return nil
        }

        return CurrencyMint.standard.make(
            identifier: .alphaCode(currency),
            exactAmount: totalCost / Decimal(totalDistance)
        )
    }
}
