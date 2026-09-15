//
//  UnitPreferences.swift
//  tankful
//
//  Created by Jake Walker on 15/09/2026.
//

import Foundation

enum DistanceUnit: String, Codable, CaseIterable {
    case kilometres
    case miles
    
    var unit: UnitLength {
        switch self {
        case .kilometres: .kilometers
        case .miles: .miles
        }
    }
}

enum VolumeUnit: String, Codable, CaseIterable {
    case litres
    case imperialGallons
    case usGallons
    
    var unit: UnitVolume {
        switch self {
        case .litres: .liters
        case .imperialGallons: .imperialGallons
        case .usGallons: .gallons
        }
    }
}
