//
//  UnitPreferences.swift
//  tankful
//
//  Created by Jake Walker on 15/09/2026.
//

import Foundation

enum DistanceUnit: String, Codable, CaseIterable, Identifiable {
    case kilometres
    case miles
    
    var id: Self { self }
    
    var unit: UnitLength {
        switch self {
        case .kilometres: .kilometers
        case .miles: .miles
        }
    }
    
    var displayName: String {
        switch self {
        case .kilometres: NSLocalizedString("Kilometres", comment: "Distance unit name")
        case .miles: NSLocalizedString("Miles", comment: "Distance unit name")
        }
    }
    
    var costPerDisplayName: String {
        switch self {
        case .kilometres: NSLocalizedString("Cost per kilometre", comment: "Metric label for cost per unit of distance")
        case .miles: NSLocalizedString("Cost per mile", comment: "Metric label for cost per unit of distance")
        }
    }
}

enum VolumeUnit: String, Codable, CaseIterable, Identifiable {
    case litres
    case imperialGallons
    case usGallons
    
    var id: Self { self }
    
    var unit: UnitVolume {
        switch self {
        case .litres: .liters
        case .imperialGallons: .imperialGallons
        case .usGallons: .gallons
        }
    }
    
    var displayName: String {
        switch self {
        case .litres: NSLocalizedString("Litres", comment: "Volume unit name")
        case .imperialGallons: NSLocalizedString("Imperial Gallons", comment: "Volume unit name")
        case .usGallons: NSLocalizedString("US Gallons", comment: "Volume unit name")
        }
    }
}

enum FuelEconomyUnit: String, Codable, CaseIterable, Identifiable {
    case mpgImperial
    case mpgUS
    case litresPer100Km
    
    var id: Self { self }
    
    var unit: UnitFuelEfficiency {
        switch self {
        case .mpgImperial: .milesPerImperialGallon
        case .mpgUS: .milesPerGallon
        case .litresPer100Km: .litersPer100Kilometers
        }
    }
    
    var displayName: String {
        switch self {
        case .mpgImperial: NSLocalizedString("MPG (Imperial)", comment: "Fuel economy unit name")
        case .mpgUS: NSLocalizedString("MPG (US)", comment: "Fuel economy unit name")
        case .litresPer100Km: NSLocalizedString("Litres per 100km", comment: "Fuel economy unit name")
        }
    }
}
