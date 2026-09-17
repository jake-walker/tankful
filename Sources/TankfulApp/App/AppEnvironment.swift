//
//  AppEnvironment.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

import Foundation
import TankfulDomain
import TankfulPersistence
import TankfulSync
import Currency
import SkipFuse
import Observation

#if canImport(TankfulIntents)
import TankfulIntents
#endif

@MainActor
@Observable final class AppEnvironment {
    private static let currentVehicleKey = "currentVehicleID"
    private static let distanceUnitKey = "distanceUnit"
    private static let volumeUnitKey = "volumeUnit"
    private static let fuelEconomyUnitKey = "fuelEconomyUnit"
    private static let syncConfigurationKey = "syncConfiguration"
    private static let lastSuccessfulSyncKey = "lastSuccessfulSync"
    
    let router: AppRouter
    
    let vehicleRepository: any VehicleRepository
    let fuelLogRepository: any FuelLogRepository
    
    let vehicleController: VehicleController
    let fuelLogController: FuelLogController
    
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
    
    var fuelEconomyUnit: FuelEconomyUnit = .mpgImperial {
        didSet {
            UserDefaults.standard.set(fuelEconomyUnit.rawValue, forKey: Self.fuelEconomyUnitKey)
        }
    }

    /// The selected backend configuration, used to create a sync coordinator at launch.
    var syncConfiguration: SyncConfiguration? {
        didSet {
            if let syncConfiguration,
               let data = try? JSONEncoder().encode(syncConfiguration) {
                UserDefaults.standard.set(data, forKey: Self.syncConfigurationKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.syncConfigurationKey)
            }
        }
    }

    private(set) var syncStatus: SyncEngine.Status = .idle(lastSuccessfulSync: nil) {
        didSet {
            if let lastSuccessfulSync = syncStatus.lastSuccessfulSync {
                UserDefaults.standard.set(lastSuccessfulSync, forKey: Self.lastSuccessfulSyncKey)
            }
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
        TankfulFormatter(distanceUnit: distanceUnit, volumeUnit: volumeUnit, fuelEconomyUnit: fuelEconomyUnit)
    }
    
    init(
        router: AppRouter,
        vehicleRepository: any VehicleRepository,
        fuelLogRepository: any FuelLogRepository,
    ) {
        self.router = router
        self.vehicleRepository = vehicleRepository
        self.fuelLogRepository = fuelLogRepository
        
        self.vehicleController = VehicleController(repository: vehicleRepository)
        self.fuelLogController = FuelLogController(repository: fuelLogRepository)

        if let rawDistanceUnit = UserDefaults.standard.string(forKey: Self.distanceUnitKey),
           let distanceUnit = DistanceUnit(rawValue: rawDistanceUnit) {
            self.distanceUnit = distanceUnit
        }

        if let rawVolumeUnit = UserDefaults.standard.string(forKey: Self.volumeUnitKey),
           let volumeUnit = VolumeUnit(rawValue: rawVolumeUnit) {
            self.volumeUnit = volumeUnit
        }
        
        if let rawFuelEconomyUnit = UserDefaults.standard.string(forKey: Self.fuelEconomyUnitKey),
           let fuelEconomyUnit = FuelEconomyUnit(rawValue: rawFuelEconomyUnit) {
            self.fuelEconomyUnit = fuelEconomyUnit
        }
        
        if let id = UserDefaults.standard.string(
            forKey: Self.currentVehicleKey
        ) {
            self.currentVehicleID = Vehicle.ID(uuidString: id)
        }

        if let data = UserDefaults.standard.data(forKey: Self.syncConfigurationKey) {
            self.syncConfiguration = try? JSONDecoder().decode(
                SyncConfiguration.self,
                from: data
            )
        }

        if let lastSuccessfulSync = UserDefaults.standard.object(
            forKey: Self.lastSuccessfulSyncKey
        ) as? Date {
            self.syncStatus = .idle(lastSuccessfulSync: lastSuccessfulSync)
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

    func syncNow() async throws {
        guard let syncConfiguration else {
            throw SyncActionError.configurationMissing
        }

        let backend: any SyncBackend
        switch syncConfiguration.type {
        case .tracktor:
            backend = TracktorBackend(client: HTTPClient(configuration: syncConfiguration), credentials: syncConfiguration.authentication)
        }

        let engine = SyncEngine(
            backend: backend,
            vehicleRepository: vehicleRepository,
            fuelLogRepository: fuelLogRepository,
            lastSuccessfulSync: syncStatus.lastSuccessfulSync
        )

        syncStatus = .syncing
        do {
            try await engine.sync()
            syncStatus = engine.status
            await refreshVehicleSpotlightIndex()
        } catch {
            syncStatus = engine.status
            throw error
        }
    }

    func refreshVehicleSpotlightIndex() async {
        #if canImport(TankfulIntents)
        if #available(iOS 26.0, macOS 26.0, *) {
            try? await TankfulIntentsEnvironment.refreshVehicleIndex()
        }
        #endif
    }
    
    func backgroundSyncIfNeeded() async {
        if let lastSuccessfulSync = syncStatus.lastSuccessfulSync,
           Date.now.timeIntervalSince(lastSuccessfulSync) < 60 {
            return
        }
        
        do {
            try await syncNow()
        } catch {
            print("Failed to sync: \(error.localizedDescription)")
        }
    }
}

private enum SyncActionError: LocalizedError {
    case configurationMissing

    var errorDescription: String? {
        "Configure a sync backend before starting a sync."
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
            fuelLogRepository: fuelLogRepository,
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
