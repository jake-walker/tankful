import AppIntents

@available(anyAppleOS 26.0, *)
struct GetLastFuelLogIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Latest Fuel Log"
    static let description = IntentDescription("Gets the most recent fuel log for a vehicle.")
    static var supportedModes: IntentModes { .background }

    @Parameter(title: "Vehicle")
    var vehicle: VehicleEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Get the latest fuel log for \(\.$vehicle)")
    }

    func perform() async throws -> some ReturnsValue<FuelLogEntity> & ProvidesDialog {
        let fuelLog = try await TankfulIntentsEnvironment.latestFuelLog(for: vehicle)
        let date = fuelLog.date.formatted(date: .abbreviated, time: .omitted)

        return .result(
            value: fuelLog,
            dialog: "The latest fuel log for \(vehicle.name) was on \(date)."
        )
    }
}
//  GetLastFuelLogIntent.swift
//  tankful
//
//  Created by Jake Walker on 17/09/2026.
//
