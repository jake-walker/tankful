//
//  LubeLoggerUnits.swift
//  tankful
//
//  Created by Jake Walker on 21/09/2026.
//

import Currency
import Foundation

public struct LubeLoggerUnits {
    let distance: UnitLength
    let volume: UnitVolume
    let currency: any CurrencyDescriptor.Type

    public init(distance: UnitLength, volume: UnitVolume, currency: any CurrencyDescriptor.Type) {
        self.distance = distance
        self.volume = volume
        self.currency = currency
    }
}
