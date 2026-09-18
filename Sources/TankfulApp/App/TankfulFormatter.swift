//
//  TankfulFormatter.swift
//  tankful
//
//  Created by Jake Walker on 15/09/2026.
//

import Foundation
import TankfulDomain

struct TankfulFormatter {
    let distanceUnit: DistanceUnit
    let volumeUnit: VolumeUnit
    let fuelEconomyUnit: FuelEconomyUnit

    func odometer(_ value: Measurement<UnitLength>) -> FormattedMeasurement {
        let value = value.converted(to: distanceUnit.unit)

        return FormattedMeasurement(
            value: value.value.formatted(.number.precision(.fractionLength(0))),
            symbol: value.unit.symbol
        )
    }

    func distance(_ value: Measurement<UnitLength>, fractionLength: Int = 1) -> FormattedMeasurement {
        let value = value.converted(to: distanceUnit.unit)

        return FormattedMeasurement(
            value: value.value.formatted(.number.precision(.fractionLength(fractionLength))),
            symbol: value.unit.symbol
        )
    }

    func volume(_ value: Measurement<UnitVolume>) -> FormattedMeasurement {
        let value = value.converted(to: volumeUnit.unit)

        return FormattedMeasurement(
            value: value.value.formatted(.number.precision(.fractionLength(2))),
            symbol: value.unit.symbol
        )
    }

    func economy(_ value: Measurement<UnitFuelEfficiency>) -> FormattedMeasurement {
        let value = value.converted(to: fuelEconomyUnit.unit)

        return FormattedMeasurement(
            value: value.value.formatted(.number.precision(.fractionLength(1))),
            symbol: value.unit.symbol
        )
    }
}

struct FormattedMeasurement: CustomStringConvertible {
    let value: String
    let symbol: String

    var description: String {
        "\(value) \(symbol)"
    }
}
