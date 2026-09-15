//
//  FuelEconomy.swift
//  tankful
//
//  Created by Jake Walker on 15/09/2026.
//

import Foundation

public struct FuelEconomy {
    public let distance: Measurement<UnitLength>
    public let volume: Measurement<UnitVolume>
    
    public var milesPerImperialGallon: Double {
        let miles = distance.converted(to: .miles).value
        let gallons = volume.converted(to: .imperialGallons).value
        
        return miles / gallons
    }
    
    public var litresPer100Kilometres: Double {
        let kilometres = distance.converted(to: .kilometers).value
        let litres = volume.converted(to: .liters).value
        
        return litres / kilometres * 100
    }
}
