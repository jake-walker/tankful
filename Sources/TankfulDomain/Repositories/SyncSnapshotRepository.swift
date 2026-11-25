@MainActor
public protocol SyncSnapshotRepository {
    func replaceSnapshot(vehicles: [Vehicle], fuelLogs: [FuelLog]) throws
}
