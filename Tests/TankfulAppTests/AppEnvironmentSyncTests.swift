import Foundation
@testable import TankfulApp
import TankfulDomain
import TankfulPersistence
import TankfulSync
import Testing

@MainActor
struct AppEnvironmentSyncTests {
    @Test func overlappingSyncIsRejected() async throws {
        let previousConfiguration = UserDefaults.standard.data(forKey: "syncConfiguration")
        defer {
            UserDefaults.standard.set(previousConfiguration, forKey: "syncConfiguration")
        }

        let database = try TankfulDatabase.inMemory()
        let backend = PausingSyncBackend()
        let environment = AppEnvironment(
            router: AppRouter(),
            vehicleRepository: SQLiteVehicleRepository(database: database),
            fuelLogRepository: SQLiteFuelLogRepository(database: database),
            snapshotRepository: SQLiteSyncSnapshotRepository(database: database)
        )
        environment.syncConfiguration = try SyncConfiguration(
            type: .tracktor,
            baseURL: #require(URL(string: "https://example.com"))
        )

        let firstSync = Task { try await environment.syncNow(using: backend) }
        var started = backend.started.makeAsyncIterator()
        _ = await started.next()

        await #expect(throws: SyncEngine.Error.self) {
            try await environment.syncNow(using: backend)
        }
        #expect(backend.fetchCount == 1)

        backend.failFetch()
        await #expect(throws: PausingSyncBackend.Failure.self) {
            try await firstSync.value
        }
        #expect(backend.fetchCount == 1)
        if case .failed = environment.syncStatus {
            // The first sync's error is still reported after the second request is rejected.
        } else {
            Issue.record("Expected the first sync to fail")
        }
    }
}

@MainActor
private final class PausingSyncBackend: SyncBackend {
    enum Failure: Error {
        case intentional
    }

    private let startedContinuation: AsyncStream<Void>.Continuation
    let started: AsyncStream<Void>
    private var pendingFetch: CheckedContinuation<[Vehicle], any Error>?
    private(set) var fetchCount = 0

    init() {
        (started, startedContinuation) = AsyncStream.makeStream(of: Void.self)
    }

    func fetchVehicles() async throws -> [Vehicle] {
        fetchCount += 1
        startedContinuation.yield(())
        return try await withCheckedThrowingContinuation { continuation in
            pendingFetch = continuation
        }
    }

    func failFetch() {
        pendingFetch?.resume(throwing: Failure.intentional)
        pendingFetch = nil
    }

    func fetchFuelLogs(remoteVehicleID _: String) async throws -> [FuelLog] {
        []
    }

    func createVehicle(_: Vehicle) async throws -> String {
        fatalError("Unexpected write")
    }

    func updateVehicle(_: Vehicle) async throws {
        fatalError("Unexpected write")
    }

    func deleteVehicle(remoteID _: String) async throws {
        fatalError("Unexpected write")
    }

    func createFuelLog(_: FuelLog, remoteVehicleID _: String) async throws -> String {
        fatalError("Unexpected write")
    }

    func updateFuelLog(_: FuelLog, remoteVehicleID _: String) async throws {
        fatalError("Unexpected write")
    }

    func deleteFuelLog(remoteID _: String, remoteVehicleID _: String) async throws {
        fatalError("Unexpected write")
    }
}
