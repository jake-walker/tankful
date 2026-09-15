//
//  AppRoute.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

import TankfulDomain

enum AppRoute: Hashable {
    case settings
    case addVehicle
    case addFuelLog
    case fuelLog(FuelLog.ID)
    case fuelLogs
    case vehicle(Vehicle.ID)
}
