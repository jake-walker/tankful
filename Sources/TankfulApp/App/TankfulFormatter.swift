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
    
    func odometer(_ value: Measurement<UnitLength>) -> String {
        let value = value.converted(to: distanceUnit.unit)
        
        return value.value.formatted(.number.precision(.fractionLength(0))) + " " + value.unit.symbol
    }
    
    func distance(_ value: Measurement<UnitLength>) -> String {
        let value = value.converted(to: distanceUnit.unit)
        
        return value.value.formatted(.number.precision(.fractionLength(1))) + " " + value.unit.symbol
    }
    
    func volume(_ value: Measurement<UnitVolume>) -> String {
        let value = value.converted(to: volumeUnit.unit)
        
        return value.value.formatted(.number.precision(.fractionLength(2))) + " " + value.unit.symbol
    }
    
    func economy(_ value: FuelEconomy) -> String {
        return value.milesPerImperialGallon.formatted(.number.precision(.fractionLength(1))) + " mpg"
    }
}
