//
//  TankfulIntentsError.swift
//  tankful
//
//  Created by Jake Walker on 17/09/2026.
//

import Foundation

public enum TankfulIntentsError: Error, CustomLocalizedStringResourceConvertible {
    case failedToInitialize
    case fuelLogNotFound
    case noFuelLogs(vehicleName: String)
    case noFuelEconomy(vehicleName: String)
    case noOdometer(vehicleName: String)
    case unableToOpenFuelLog
    case unableToOpenVehicle

    public var localizedStringResource: LocalizedStringResource {
        switch self {
        case .failedToInitialize:
            "Tankful couldn't open its database."
        case .fuelLogNotFound:
            "That fill-up no longer exists."
        case let .noFuelLogs(vehicleName):
            "There are no fill-ups for \(vehicleName)."
        case let .noFuelEconomy(vehicleName):
            "There isn't enough information to calculate fuel economy for \(vehicleName)."
        case let .noOdometer(vehicleName):
            "The latest fill-up for \(vehicleName) doesn't include an odometer reading."
        case .unableToOpenFuelLog:
            "Tankful couldn't open that fill-up."
        case .unableToOpenVehicle:
            "Tankful couldn't open that vehicle."
        }
    }
}
