//
//  AppEnvironment.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

import Foundation
import TankfulDomain
import TankfulPersistence
import Currency

@MainActor
final class AppEnvironment: Observable {
    private static let currentVehicleKey = "currentVehicleID"
    private static let distanceUnitKey = "distanceUnit"
    private static let volumeUnitKey = "volumeUnit"
    
    let router: AppRouter
    
    let vehicleRepository: any VehicleRepository
    let fuelLogRepository: any FuelLogRepository
    
    var distanceUnit: DistanceUnit = .miles {
        didSet {
            UserDefaults.standard.set(distanceUnit.rawValue, forKey: Self.distanceUnitKey)
        }
    }
    var volumeUnit: VolumeUnit = .litres {
        didSet {
            UserDefaults.standard.set(volumeUnit.rawValue, forKey: Self.volumeUnitKey)
        }
    }

    var vehicleChangeVersion: Int = 0
    
    var currentVehicleID: Vehicle.ID? {
        didSet {
            if let currentVehicleID {
                UserDefaults.standard.set(
                    currentVehicleID.uuidString,
                    forKey: Self.currentVehicleKey
                )
            } else {
                UserDefaults.standard.removeObject(
                    forKey: Self.currentVehicleKey
                )
            }
        }
    }
    
    var formatter: TankfulFormatter {
        TankfulFormatter(distanceUnit: distanceUnit, volumeUnit: volumeUnit)
    }
    
    init(
        router: AppRouter,
        vehicleRepository: any VehicleRepository,
        fuelLogRepository: any FuelLogRepository
    ) {
        self.router = router
        self.vehicleRepository = vehicleRepository
        self.fuelLogRepository = fuelLogRepository

        if let rawDistanceUnit = UserDefaults.standard.string(forKey: Self.distanceUnitKey),
           let distanceUnit = DistanceUnit(rawValue: rawDistanceUnit) {
            self.distanceUnit = distanceUnit
        }

        if let rawVolumeUnit = UserDefaults.standard.string(forKey: Self.volumeUnitKey),
           let volumeUnit = VolumeUnit(rawValue: rawVolumeUnit) {
            self.volumeUnit = volumeUnit
        }
        
        if let id = UserDefaults.standard.string(
            forKey: Self.currentVehicleKey
        ) {
            self.currentVehicleID = Vehicle.ID(uuidString: id)
        }
    }
    
    func resolveCurrentVehicle() async throws {
        let vehicles = try await vehicleRepository.vehicles()
        
        if let currentVehicleID,
           vehicles.contains(where: { $0.id == currentVehicleID }) {
            return
        }
        
        currentVehicleID = vehicles.first?.id
    }

    func selectVehicle(id: Vehicle.ID) {
        currentVehicleID = id
        vehicleChangeVersion += 1
    }
}

#if DEBUG
@MainActor
extension AppEnvironment {
    private static let seededPreviewFuelLogID = FuelLog.ID()

    var previewFuelLogID: FuelLog.ID {
        Self.seededPreviewFuelLogID
    }

    static func preview() -> AppEnvironment {
        let database = try! TankfulDatabase.inMemory()
        
        let vehicleRepository = SQLiteVehicleRepository(database: database)
        let fuelLogRepository = SQLiteFuelLogRepository(database: database)

        let vehicles = [
            Vehicle(
                id: UUID(),
                make: "Volkswagen",
                model: "Golf",
                year: 2021,
                fuelType: .petrol
            ),
            Vehicle(
                id: UUID(),
                make: "Volvo",
                model: "XC40",
                year: 2023,
                fuelType: .diesel
            )
        ]

        for vehicle in vehicles {
            try! vehicleRepository.save(vehicle)
        }

        seedFuelLogs(
            for: vehicles[0],
            startingOdometer: 24_000,
            count: 6,
            firstFuelLogID: seededPreviewFuelLogID,
            using: fuelLogRepository
        )
        seedFuelLogs(
            for: vehicles[1],
            startingOdometer: 11_500,
            count: 4,
            using: fuelLogRepository
        )
        
        let env = AppEnvironment(
            router: AppRouter(),
            vehicleRepository: vehicleRepository,
            fuelLogRepository: fuelLogRepository
        )
        
        env.currentVehicleID = vehicles[0].id
        
        return env
    }

    private static func seedFuelLogs(
        for vehicle: Vehicle,
        startingOdometer: Int64,
        count: Int,
        firstFuelLogID: FuelLog.ID? = nil,
        using repository: SQLiteFuelLogRepository
    ) {
        var odometer = startingOdometer
        let calendar = Calendar.current

        for index in 0..<count {
            odometer += Int64.random(in: 350...650)

            let volume = (Double.random(in: 35...55) * 10).rounded() / 10
            let pricePerLitre = Double.random(in: 1.38...1.62)
            let cost = (volume * pricePerLitre * 100).rounded() / 100
            let daysAgo = ((count - index) * 14) + Int.random(in: -2...2)

            let fuelLog = FuelLog(
                id: index == 0 ? firstFuelLogID ?? UUID() : UUID(),
                vehicleID: vehicle.id,
                date: calendar.date(byAdding: .day, value: -daysAgo, to: .now)!,
                odometer: Measurement(value: Double(odometer), unit: .miles),
                volume: Measurement(value: Double(volume), unit: .liters),
                cost: GBP(exactAmount: Decimal(cost)),
                filled: true,
                missedLast: index == 0,
                notes: index == count - 1 ? "Regular fill-up" : nil
            )

            try! repository.save(fuelLog)
        }
    }
}
#endif
