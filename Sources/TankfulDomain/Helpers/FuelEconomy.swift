//
//  FuelEconomy.swift
//  tankful
//
//  Created by Jake Walker on 17/09/2026.
//

import Foundation

func calculateFuelEconomy(distance: Measurement<UnitLength>, volume: Measurement<UnitVolume>) -> Measurement<UnitFuelEfficiency> {
    Measurement(
        value: volume.converted(to: .liters).value / (distance.converted(to: .kilometers).value / 100),
        unit: .litersPer100Kilometers
    )
}
