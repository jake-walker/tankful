import Foundation
import SkipSQLCore
import TankfulDomain

public final class SQLiteSyncSnapshotRepository: SyncSnapshotRepository {
    public enum Error: Swift.Error {
        case missingRemoteID
        case duplicateRemoteID
        case missingVehicle
    }

    private let database: TankfulDatabase

    public init(database: TankfulDatabase) {
        self.database = database
    }

    public func replaceSnapshot(vehicles: [Vehicle], fuelLogs: [FuelLog]) throws {
        try database.ctx.transaction {
            let existingVehicles = try database.ctx.fetchAll(VehicleRecord.self)
            let existingFuelLogs = try database.ctx.fetchAll(FuelLogRecord.self)

            var vehicleIDsByRemoteID: [String: UUID] = [:]
            for record in existingVehicles {
                if let remoteID = record.remoteID {
                    guard try vehicleIDsByRemoteID.updateValue(record.toDomain().id, forKey: remoteID) == nil else {
                        throw Error.duplicateRemoteID
                    }
                }
            }

            var fuelLogIDsByRemoteID: [String: UUID] = [:]
            for record in existingFuelLogs {
                if let remoteID = record.remoteID {
                    guard try fuelLogIDsByRemoteID.updateValue(record.toDomain().id, forKey: remoteID) == nil else {
                        throw Error.duplicateRemoteID
                    }
                }
            }

            var vehicleIDsBySnapshotID: [UUID: UUID] = [:]
            var seenVehicleRemoteIDs: Set<String> = []
            let vehicleRecords = try vehicles.map { vehicle in
                guard let remoteID = vehicle.remoteID else {
                    throw Error.missingRemoteID
                }
                guard seenVehicleRemoteIDs.insert(remoteID).inserted else {
                    throw Error.duplicateRemoteID
                }

                let localID = vehicleIDsByRemoteID[remoteID] ?? vehicle.id
                vehicleIDsBySnapshotID[vehicle.id] = localID
                return try VehicleRecord(vehicle.with(id: localID))
            }

            var seenFuelLogRemoteIDs: Set<String> = []
            let fuelLogRecords = try fuelLogs.map { fuelLog in
                guard let remoteID = fuelLog.remoteID else {
                    throw Error.missingRemoteID
                }
                guard seenFuelLogRemoteIDs.insert(remoteID).inserted else {
                    throw Error.duplicateRemoteID
                }
                guard let localVehicleID = vehicleIDsBySnapshotID[fuelLog.vehicleID] else {
                    throw Error.missingVehicle
                }

                let localID = fuelLogIDsByRemoteID[remoteID] ?? fuelLog.id
                return try FuelLogRecord(fuelLog.with(id: localID, vehicleID: localVehicleID))
            }

            try database.ctx.deleteAll(FuelLogRecord.self)
            try database.ctx.deleteAll(VehicleRecord.self)

            for record in vehicleRecords {
                try database.ctx.insert(record)
            }
            for record in fuelLogRecords {
                try database.ctx.insert(record)
            }
        }
    }
}
