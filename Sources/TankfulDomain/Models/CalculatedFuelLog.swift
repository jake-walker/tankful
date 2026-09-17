//
//  CalculatedFuelLog.swift
//  tankful
//
//  Created by Jake Walker on 15/09/2026.
//

import Foundation
import Currency

public struct CalculatedFuelLog: Identifiable {
    public let log: FuelLog
    public let distance: Measurement<UnitLength>?
    
    public var id: FuelLog.ID { log.id }
    
    public var economy: Measurement<UnitFuelEfficiency>? {
        guard !log.missedLast,
              let distance,
              let volume = log.volume else {
            return nil
        }
        
        return calculateFuelEconomy(distance: distance, volume: volume)
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
    }
}

extension Array where Element == FuelLog {
    private func calculateDistance(from previous: FuelLog, to current: FuelLog) -> Measurement<UnitLength>? {
        guard let previousOdometer = previous.odometer,
              let currentOdometer = current.odometer else {
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
    
    private func calculateEconomy(from previous: FuelLog, to current: FuelLog) -> Measurement<UnitFuelEfficiency>? {
        guard let distance = calculateDistance(from: previous, to: current),
              let volume = current.volume else {
            return nil
        }
        
        return calculateFuelEconomy(distance: distance, volume: volume)
    }
    
    public func calculated() -> [CalculatedFuelLog] {
        let sortedLogs = sorted { $0.date < $1.date }

        let calculatedLogs = sortedLogs.enumerated()
            .map { index, log in
                guard index > 0 else {
                    return CalculatedFuelLog(
                        log: log,
                        distance: nil,
                    )
                }
                
                let previous = sortedLogs[index - 1]
                
                let distance = calculateDistance(from: previous, to: log)
                
                return CalculatedFuelLog(
                    log: log,
                    distance: distance
                )
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

extension Collection where Element == CalculatedFuelLog {
    public var totalDistance: Measurement<UnitLength> {
        let metres = compactMap(\.distance)
            .reduce(0) {
                $0 + $1.converted(to: .meters).value
            }
        
        return Measurement(value: metres, unit: .meters)
    }
    
    public var totalVolume: Measurement<UnitVolume> {
        let litres = compactMap(\.log.volume)
            .reduce(0) {
                $0 + $1.converted(to: .liters).value
            }
        
        return Measurement(value: litres, unit: .liters)
    }
    
    public var averageFuelEconomy: Measurement<UnitFuelEfficiency>? {
        let validLogs = filter {
            !$0.log.missedLast && $0.distance != nil && $0.log.volume != nil
        }
        
        let distance = validLogs.compactMap(\.distance)
            .reduce(0) {
                $0 + $1.converted(to: .meters).value
            }
        
        let volume = validLogs.compactMap(\.log.volume)
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
    
    public func averageCostPerDistance(unit: UnitLength) -> (any CurrencyValue)? {
        let logs = filter {
            !$0.log.missedLast && $0.distance != nil
        }
        
        guard let currency = logs.first?.log.cost.descriptor.alphabeticCode,
              logs.allSatisfy({ $0.log.cost.descriptor.alphabeticCode == currency }) else {
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
