import Currency
import Foundation
import TankfulDomain
import Testing

func makeVehicle(syncState: SyncState, remoteID: String? = nil) -> Vehicle {
    Vehicle(
        id: UUID(),
        name: "Test car",
        fuelType: .petrol,
        remoteID: remoteID,
        syncState: syncState
    )
}

func makeFuelLog(
    vehicleID: Vehicle.ID,
    syncState: SyncState,
    remoteID: String? = nil
) throws -> FuelLog {
    let cost = try #require(CurrencyMint.standard.make(
        identifier: .alphaCode("GBP"),
        exactAmount: Decimal(6050) / 100
    ))

    return FuelLog(
        id: UUID(),
        vehicleID: vehicleID,
        date: Date(timeIntervalSince1970: 1_700_000_000),
        odometer: Measurement(value: 10000, unit: .kilometers),
        volume: Measurement(value: 40, unit: .liters),
        cost: cost,
        filled: true,
        missedLast: true,
        notes: "First fill-up",
        remoteID: remoteID,
        syncState: syncState
    )
}
