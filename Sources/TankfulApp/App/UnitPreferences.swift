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
        case .kilometres: "Kilometres"
        case .miles: "Miles"
        }
    }
    
    var costPerDisplayName: String {
        switch self {
        case .kilometres: "Cost per kilometre"
        case .miles: "Cost per mile"
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
        case .litres: "Litres"
        case .imperialGallons: "Imperial Gallons"
        case .usGallons: "US Gallons"
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
        case .mpgImperial: "MPG (Imperial)"
        case .mpgUS: "MPG (US)"
        case .litresPer100Km: "Litres per 100km"
        }
    }
}
