//
//  SyncEngineTests.swift
//  tankful
//
//  Created by Jake Walker on 04/11/2026.
//

import Foundation
import TankfulDomain
import TankfulPersistence
@testable import TankfulSync
import Testing

@MainActor
struct SyncEngineTests {
    @Test func createdVehicleAndFillUp() async throws {
        let vehicle = makeVehicle(syncState: .created)
        let fuelLog = try makeFuelLog(vehicleID: vehicle.id, syncState: .created)
        let fixture = try await SyncTestFixture.make(
            localVehicles: [vehicle],
            localFuelLogs: [fuelLog]
        )

        try await fixture.engine.sync()

        #expect(fixture.backend.callLog == [
            .createVehicle(vehicle),
            .createFuelLog(fuelLog, remoteVehicleID: "0"),
            .fetchVehicles,
            .fetchFuelLogs,
        ])

        var expectedVehicle = vehicle
        expectedVehicle.remoteID = "0"
        expectedVehicle.syncState = .synced
        var expectedFuelLog = fuelLog
        expectedFuelLog.remoteID = "0"
        expectedFuelLog.syncState = .synced

        #expect(fixture.backend.vehicles == [expectedVehicle])
        #expect(fixture.backend.fuelLogs == [expectedFuelLog])

        let storedVehicles = try await fixture.vehicleRepository.vehicles()
        let storedFuelLogs = try await fixture.fuelLogRepository.fuelLogs()
        #expect(storedVehicles == [expectedVehicle])
        #expect(storedFuelLogs == [expectedFuelLog])

        let pendingVehicles = try await fixture.vehicleRepository.pendingSync()
        let pendingFuelLogs = try await fixture.fuelLogRepository.pendingSync()
        #expect(pendingVehicles.isEmpty)
        #expect(pendingFuelLogs.isEmpty)
    }

    @Test func importsExistingRecordsAndKeepsIDsOnRepeatSync() async throws {
        let vehicle = makeVehicle(syncState: .synced, remoteID: "test1")
        let fuelLog = try makeFuelLog(vehicleID: vehicle.id, syncState: .synced, remoteID: "test2")

        let fixture = try await SyncTestFixture.make(
            remoteVehicles: [vehicle],
            remoteFuelLogs: [fuelLog]
        )

        try await fixture.engine.sync()

        // change remote ids
        let firstVehicleID = try #require((await fixture.vehicleRepository.vehicles()).first).id
        let firstLogID = try #require((await fixture.fuelLogRepository.fuelLogs()).first).id

        fixture.backend.vehicles[0].id = UUID()
        fixture.backend.fuelLogs[0].id = UUID()
        fixture.backend.fuelLogs[0].vehicleID = fixture.backend.vehicles[0].id

        try await fixture.engine.sync()

        // no creates or updates should be made
        #expect(fixture.backend.callLog == [
            .fetchVehicles,
            .fetchFuelLogs,
            .fetchVehicles,
            .fetchFuelLogs,
        ])

        let storedVehicles = try await fixture.vehicleRepository.vehicles()
        let storedFuelLogs = try await fixture.fuelLogRepository.fuelLogs()
        #expect(try #require(storedVehicles.first).id == firstVehicleID)
        #expect(try #require(storedFuelLogs.first).id == firstLogID)
        #expect(storedVehicles.count == 1)
        #expect(storedFuelLogs.count == 1)

        let pendingVehicles = try await fixture.vehicleRepository.pendingSync()
        let pendingFuelLogs = try await fixture.fuelLogRepository.pendingSync()
        #expect(pendingVehicles.isEmpty)
        #expect(pendingFuelLogs.isEmpty)
    }

    @Test func modifiedRecords() async throws {
        var localVehicle = makeVehicle(syncState: .synced, remoteID: "test1")
        let remoteVehicle = localVehicle
        localVehicle.syncState = .modified
        localVehicle.name = "TEST"
        var localFuelLog = try makeFuelLog(vehicleID: localVehicle.id, syncState: .synced, remoteID: "test2")
        let remoteFuelLog = localFuelLog
        localFuelLog.syncState = .modified
        localFuelLog.notes = "NOTES"

        let fixture = try await SyncTestFixture.make(
            localVehicles: [localVehicle],
            localFuelLogs: [localFuelLog],
            remoteVehicles: [remoteVehicle],
            remoteFuelLogs: [remoteFuelLog]
        )

        try await fixture.engine.sync()

        #expect(try fixture.backend.callLog == [
            .updateVehicle(localVehicle),
            .updateFuelLog(localFuelLog, remoteVehicleID: #require(localVehicle.remoteID)),
            .fetchVehicles,
            .fetchFuelLogs,
        ])

        // do local ids stay stable?
        let storedVehicles = try await fixture.vehicleRepository.vehicles()
        let storedFuelLogs = try await fixture.fuelLogRepository.fuelLogs()
        #expect(try #require(storedVehicles.first).id == localVehicle.id)
        #expect(try #require(storedFuelLogs.first).id == localFuelLog.id)
        #expect(try #require(storedVehicles.first).name == "TEST")
        #expect(try #require(storedFuelLogs.first).notes == "NOTES")

        let pendingVehicles = try await fixture.vehicleRepository.pendingSync()
        let pendingFuelLogs = try await fixture.fuelLogRepository.pendingSync()
        #expect(pendingVehicles.isEmpty)
        #expect(pendingFuelLogs.isEmpty)

        #expect(try #require(fixture.backend.vehicles.first).name == "TEST")
        #expect(try #require(fixture.backend.fuelLogs.first).notes == "NOTES")
    }

    @Test func failedRemoteFetchPreservesLocalData() async throws {
        // Make the fake backend fail while fetching a vehicle's fuel logs.
        // Assert sync reports failure, no local records are replaced or removed,
        // and the last successful sync date is unchanged.

        let vehicle = makeVehicle(syncState: .synced, remoteID: "test1")
        let fuelLog = try makeFuelLog(vehicleID: vehicle.id, syncState: .synced, remoteID: "test2")

        let fixture = try await SyncTestFixture.make(
            localVehicles: [vehicle],
            localFuelLogs: [fuelLog],
            remoteVehicles: [vehicle],
            lastSuccessfulSync: .distantPast
        )

        fixture.backend.fetchFuelLogsError = FakeSyncBackend.Error.intentionalFailure

        await #expect(throws: FakeSyncBackend.Error.intentionalFailure) {
            try await fixture.engine.sync()
        }

        #expect(fixture.backend.callLog == [.fetchVehicles, .fetchFuelLogs])
        #expect(try await fixture.vehicleRepository.vehicles() == [vehicle])
        #expect(try await fixture.fuelLogRepository.fuelLogs() == [fuelLog])
        #expect(fixture.engine.status.lastSuccessfulSync == .distantPast)

        if case let .failed(lastSuccessfulSync, _) = fixture.engine.status {
            #expect(lastSuccessfulSync == .distantPast)
        } else {
            Issue.record("Expected sync status to be failed")
        }
    }

    @Test func failedSnapshotReplacementPreservesLocalData() async throws {
        let originalVehicle = makeVehicle(syncState: .synced, remoteID: "old-vehicle")
        let originalLog = try makeFuelLog(
            vehicleID: originalVehicle.id,
            syncState: .synced,
            remoteID: "old-log"
        )
        let fixture = try await SyncTestFixture.make(
            localVehicles: [originalVehicle],
            localFuelLogs: [originalLog]
        )

        let remoteVehicle = makeVehicle(syncState: .synced, remoteID: "new-vehicle")
        var conflictingVehicle = remoteVehicle
        conflictingVehicle.remoteID = "another-vehicle"
        let snapshotRepository = SQLiteSyncSnapshotRepository(database: fixture.database)

        #expect(throws: (any Error).self) {
            try snapshotRepository.replaceSnapshot(
                vehicles: [remoteVehicle, conflictingVehicle],
                fuelLogs: []
            )
        }

        #expect(try await fixture.vehicleRepository.vehicles() == [originalVehicle])
        #expect(try await fixture.fuelLogRepository.fuelLogs() == [originalLog])
    }
}
