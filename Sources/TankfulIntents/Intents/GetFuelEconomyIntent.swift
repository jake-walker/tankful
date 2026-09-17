import AppIntents

@available(anyAppleOS 26.0, *)
struct GetFuelEconomyIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Average Fuel Economy"
    static let description = IntentDescription("Calculates a vehicle's average fuel economy from all valid fuel logs.")
    static var supportedModes: IntentModes { .background }

    @Parameter(title: "Vehicle")
    var vehicle: VehicleEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Get the average fuel economy for \(\.$vehicle)")
    }

    func perform() async throws -> some ReturnsValue<Measurement<UnitFuelEfficiency>> & ProvidesDialog {
        let economy = try await TankfulIntentsEnvironment.averageFuelEconomy(for: vehicle)
        let formattedEconomy = "\(economy.value.formatted(.number.precision(.fractionLength(1)))) \(economy.unit.symbol)"

        return .result(
            value: economy,
            dialog: "The average fuel economy for \(vehicle.name) is \(formattedEconomy)."
        )
    }
}
//  GetFuelEconomyIntent.swift
//  tankful
//
//  Created by Jake Walker on 17/09/2026.
//
