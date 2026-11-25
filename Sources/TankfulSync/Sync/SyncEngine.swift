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
            case let .idle(date), let .failed(date, _):
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
    private let snapshotRepository: any SyncSnapshotRepository
    private let now: @Sendable () -> Date

    public init(
        backend: any SyncBackend,
        vehicleRepository: any VehicleRepository,
        fuelLogRepository: any FuelLogRepository,
        snapshotRepository: any SyncSnapshotRepository,
        lastSuccessfulSync: Date? = nil,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.backend = backend
        self.vehicleRepository = vehicleRepository
        self.fuelLogRepository = fuelLogRepository
        self.snapshotRepository = snapshotRepository
        status = .idle(lastSuccessfulSync: lastSuccessfulSync)
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
                try snapshotRepository.replaceSnapshot(vehicles: snapshot.0, fuelLogs: snapshot.1)
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
        let remoteVehicles = try await backend.fetchVehicles()
        var remoteFuelLogs: [FuelLog] = []

        for vehicle in remoteVehicles {
            if let remoteID = vehicle.remoteID {
                try remoteFuelLogs.append(contentsOf: await backend.fetchFuelLogs(remoteVehicleID: remoteID)
                    .map {
                        var l = $0
                        l.vehicleID = vehicle.id
                        return l
                    })
            }
        }

        return (remoteVehicles, remoteFuelLogs)
    }

    func createBackendVehicle(vehicle: Vehicle) async throws {
        log("Creating remote vehicle \(vehicle.displayName)")

        let newRemoteID = try await backend.createVehicle(vehicle)

        var updatedVehicle = vehicle
        updatedVehicle.remoteID = newRemoteID
        updatedVehicle.syncState = .synced

        try await vehicleRepository.save(updatedVehicle)
    }

    func modifyBackendVehicle(vehicle: Vehicle) async throws {
        log("Modifying remote vehicle \(vehicle.displayName)")

        try await backend.updateVehicle(vehicle)

        var updatedVehicle = vehicle
        updatedVehicle.syncState = .synced

        try await vehicleRepository.save(updatedVehicle)
    }

    func createBackendFuelLog(fuelLog: FuelLog, remoteVehicleID: String) async throws {
        log("Creating remote fuel log \(fuelLog.id)")

        let newRemoteID = try await backend.createFuelLog(fuelLog, remoteVehicleID: remoteVehicleID)

        var updatedFuelLog = fuelLog
        updatedFuelLog.remoteID = newRemoteID
        updatedFuelLog.syncState = .synced

        try await fuelLogRepository.save(updatedFuelLog)
    }

    func modifyBackendFuelLog(fuelLog: FuelLog, remoteVehicleID: String) async throws {
        log("Modifying remote fuel log \(fuelLog.id)")

        try await backend.updateFuelLog(fuelLog, remoteVehicleID: remoteVehicleID)

        var updatedFuelLog = fuelLog
        updatedFuelLog.syncState = .synced

        try await fuelLogRepository.save(updatedFuelLog)
    }

    func lookupRemoteVehicleID(localID: Vehicle.ID) async -> String? {
        guard let vehicle = try? await vehicleRepository.vehicle(id: localID) else {
            return nil
        }

        return vehicle.remoteID
    }
}
