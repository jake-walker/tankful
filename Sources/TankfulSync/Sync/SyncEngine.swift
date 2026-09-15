import Foundation
import TankfulDomain

@MainActor
public final class SyncEngine {
    public enum Status: Equatable, Sendable {
        case idle(lastSuccessfulSync: Date?)
        case syncing
        case failed(lastSuccessfulSync: Date?, message: String)

        public var lastSuccessfulSync: Date? {
            switch self {
            case .idle(let date), .failed(let date, _):
                date
            case .syncing:
                nil
            }
        }
    }

    public enum Error: Swift.Error, LocalizedError {
        case noRemoteID
        case syncAlreadyInProgress
    }

    public private(set) var status: Status
    private var lastSuccessfulSync: Date?

    private let backend: any SyncBackend
    private let vehicleRepository: any VehicleRepository
    private let fuelLogRepository: any FuelLogRepository
    private let now: @Sendable () -> Date

    public init(
        backend: any SyncBackend,
        vehicleRepository: any VehicleRepository,
        fuelLogRepository: any FuelLogRepository,
        lastSuccessfulSync: Date? = nil,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.backend = backend
        self.vehicleRepository = vehicleRepository
        self.fuelLogRepository = fuelLogRepository
        self.status = .idle(lastSuccessfulSync: lastSuccessfulSync)
        self.lastSuccessfulSync = lastSuccessfulSync
        self.now = now
    }

    /// Synchronizes vehicles first, followed by their fuel logs.
    public func sync() async throws {
        guard case .syncing = status else {
            status = .syncing
            log("Starting manual sync.")
            do {
                try await pushPendingChanges()
                let snapshot = try await fetchRemoteSnapshot()
                try await applyRemoteSnapshot(vehicles: snapshot.0, fuelLogs: snapshot.1)
                let completedAt = now()
                lastSuccessfulSync = completedAt
                status = .idle(lastSuccessfulSync: completedAt)
                log("Sync completed successfully.")
                return
            } catch {
                status = .failed(lastSuccessfulSync: lastSuccessfulSync, message: error.localizedDescription)
                log("Sync failed: \(error.localizedDescription) [\(String(describing: error))]")
                throw error
            }
        }

        throw Error.syncAlreadyInProgress
    }
}

private extension SyncEngine {
    func log(_ message: String) {
        // Deliberately avoid request headers, credentials, cookies, and payloads.
        print("TankfulSync: \(message)")
    }

    /// Push pending local changes to the backend
    func pushPendingChanges() async throws {
        let pendingVehicles = try await vehicleRepository.pendingSync()
        let pendingFuelLogs = try await fuelLogRepository.pendingSync()
        
        log("Pushing \(pendingVehicles.count) vehicles, \(pendingFuelLogs.count) logs")
        
        for vehicle in pendingVehicles {
            switch vehicle.syncState {
            case .synced:
                continue
            case .created:
                try await createBackendVehicle(vehicle: vehicle)
            case .modified:
                try await modifyBackendVehicle(vehicle: vehicle)
            }
        }
        
        for fuelLog in pendingFuelLogs {
            guard let remoteVehicleID = await lookupRemoteVehicleID(localID: fuelLog.vehicleID) else {
                throw Error.noRemoteID
            }
            
            switch fuelLog.syncState {
            case .synced:
                continue
            case .created:
                try await createBackendFuelLog(fuelLog: fuelLog, remoteVehicleID: remoteVehicleID)
            case .modified:
                try await modifyBackendFuelLog(fuelLog: fuelLog, remoteVehicleID: remoteVehicleID)
            }
        }
    }
    
    /// Fetch complete remote snapshot
    func fetchRemoteSnapshot() async throws -> ([Vehicle], [FuelLog]) {
        let remoteVehicles = try await self.backend.fetchVehicles()
        var remoteFuelLogs: [FuelLog] = []
        
        for vehicle in remoteVehicles {
            if let remoteID = vehicle.remoteID {
                remoteFuelLogs.append(contentsOf: try await self.backend.fetchFuelLogs(remoteVehicleID: remoteID)
                    .map {
                        var l = $0
                        l.vehicleID = vehicle.id
                        return l
                    })
            }
        }
        
        return (remoteVehicles, remoteFuelLogs)
    }
    
    func applyRemoteSnapshot(vehicles: [Vehicle], fuelLogs: [FuelLog]) async throws {
        log("Building UUID map")
        let existingVehicles = try await vehicleRepository.vehicles()
        let existingFuelLogs = try await fuelLogRepository.fuelLogs()
        
        let vehicleIDs = Dictionary<String, UUID>(
            uniqueKeysWithValues: existingVehicles.compactMap { vehicle in
                guard let remoteID = vehicle.remoteID else {
                    return nil
                }
                
                return (remoteID, vehicle.id)
            }
        )
        
        let fuelLogIDs = Dictionary<String, UUID>(
            uniqueKeysWithValues: existingFuelLogs.compactMap { fuelLog in
                guard let remoteID = fuelLog.remoteID else {
                    return nil
                }
                
                return (remoteID, fuelLog.id)
            }
        )
        
        log("Applying remote snapshot (\(vehicles.count) vehicles, \(fuelLogs.count) logs)")
        
        try await self.vehicleRepository.deleteAll()
        try await self.fuelLogRepository.deleteAll()
        
        for vehicle in vehicles {
            try await self.vehicleRepository.save(vehicle.with(id: vehicleIDs[vehicle.remoteID!] ?? vehicle.id))
        }
        
        for fuelLog in fuelLogs {
            if let vehicle = vehicles.first(where: { $0.id == fuelLog.vehicleID }) {
                try await self.fuelLogRepository.save(fuelLog.with(
                    id: fuelLogIDs[fuelLog.remoteID!] ?? fuelLog.id,
                    vehicleID: vehicleIDs[vehicle.remoteID!] ?? vehicle.id
                ))
            }
        }
    }
    
    func createBackendVehicle(vehicle: Vehicle) async throws {
        log("Creating remote vehicle \(vehicle.displayName)")
        
        let newRemoteID = try await self.backend.createVehicle(vehicle)
        
        var updatedVehicle = vehicle
        updatedVehicle.remoteID = newRemoteID
        updatedVehicle.syncState = .synced
        
        try await self.vehicleRepository.save(updatedVehicle)
    }
    
    func modifyBackendVehicle(vehicle: Vehicle) async throws {
        log("Modifying remote vehicle \(vehicle.displayName)")
        
        try await self.backend.updateVehicle(vehicle)
        
        var updatedVehicle = vehicle
        updatedVehicle.syncState = .synced
        
        try await self.vehicleRepository.save(updatedVehicle)
    }
    
    func createBackendFuelLog(fuelLog: FuelLog, remoteVehicleID: String) async throws {
        log("Creating remote fuel log \(fuelLog.id)")
        
        let newRemoteID = try await self.backend.createFuelLog(fuelLog, remoteVehicleID: remoteVehicleID)
        
        var updatedFuelLog = fuelLog
        updatedFuelLog.remoteID = newRemoteID
        updatedFuelLog.syncState = .synced
        
        try await self.fuelLogRepository.save(updatedFuelLog)
    }
    
    func modifyBackendFuelLog(fuelLog: FuelLog, remoteVehicleID: String) async throws {
        log("Modifying remote fuel log \(fuelLog.id)")
        
        try await self.backend.updateFuelLog(fuelLog, remoteVehicleID: remoteVehicleID)
        
        var updatedFuelLog = fuelLog
        updatedFuelLog.syncState = .synced
        
        try await self.fuelLogRepository.save(updatedFuelLog)
    }
    
    func lookupRemoteVehicleID(localID: Vehicle.ID) async -> String? {
        guard let vehicle = try? await self.vehicleRepository.vehicle(id: localID) else {
            return nil
        }
        
        return vehicle.remoteID
    }
}
