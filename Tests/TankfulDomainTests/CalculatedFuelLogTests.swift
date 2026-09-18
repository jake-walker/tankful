import Currency
import Foundation
@testable import TankfulDomain
import Testing

struct CalculatedFuelLogTests {
    private let vehicleID = UUID()

    @Test func partialFillRollsDistanceAndVolumeIntoNextFullFill() throws {
        let logs = try [
            makeLog(day: 0, odometer: 10000, volume: 40, filled: true),
            makeLog(day: 1, odometer: 10250, volume: 20, filled: false),
            makeLog(day: 2, odometer: 10500, volume: 30, filled: true),
        ].calculated()

        #expect(logs.count == 3)

        let latest = logs[0]
        #expect(latest.distance?.converted(to: .kilometers).value == 500)
        #expect(latest.economy?.converted(to: .litersPer100Kilometers).value == 10)

        let partial = logs[1]
        #expect(partial.distance?.converted(to: .kilometers).value == 250)
        #expect(partial.economy == nil)

        #expect(logs[2].economy == nil)
    }

    @Test func missedLastInvalidatesCurrentIntervalButStartsANewBaseline() throws {
        let logs = try [
            makeLog(day: 0, odometer: 10000, volume: 40, filled: true),
            makeLog(day: 1, odometer: 10500, volume: 50, filled: true, missedLast: true),
            makeLog(day: 2, odometer: 11000, volume: 40, filled: true),
        ].calculated()

        #expect(logs[1].distance == nil)
        #expect(logs[1].economy == nil)
        #expect(logs[0].distance?.converted(to: .kilometers).value == 500)
        #expect(logs[0].economy?.converted(to: .litersPer100Kilometers).value == 8)
    }

    @Test func missingValuesPreventEconomyWithoutRemovingLogs() throws {
        let logs = try [
            makeLog(day: 0, odometer: 10000, volume: 40, filled: true),
            makeLog(day: 1, odometer: 10250, volume: nil, filled: false),
            makeLog(day: 2, odometer: 10500, volume: 30, filled: true),
            makeLog(day: 3, odometer: nil, volume: 30, filled: true),
        ].calculated()

        #expect(logs.count == 4)
        #expect(logs.allSatisfy { $0.economy == nil })
    }

    @Test func averageEconomyUsesRolledUpVolume() throws {
        let logs = try [
            makeLog(day: 0, odometer: 10000, volume: 40, filled: true),
            makeLog(day: 1, odometer: 10250, volume: 20, filled: false),
            makeLog(day: 2, odometer: 10500, volume: 30, filled: true),
        ].calculated()

        #expect(logs.averageFuelEconomy?.converted(to: .litersPer100Kilometers).value == 10)
    }

    private func makeLog(
        day: Int,
        odometer: Double?,
        volume: Double?,
        filled: Bool,
        missedLast: Bool = false
    ) throws -> FuelLog {
        let cost = try #require(CurrencyMint.standard.make(
            identifier: .alphaCode("GBP"),
            exactAmount: 50
        ))

        return FuelLog(
            id: UUID(),
            vehicleID: vehicleID,
            date: Date(timeIntervalSince1970: TimeInterval(day * 86400)),
            odometer: odometer.map { Measurement(value: $0, unit: .kilometers) },
            volume: volume.map { Measurement(value: $0, unit: .liters) },
            cost: cost,
            filled: filled,
            missedLast: missedLast
        )
    }
}
