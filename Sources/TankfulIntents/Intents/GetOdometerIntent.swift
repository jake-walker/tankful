import AppIntents

@available(anyAppleOS 26.0, *)
struct GetOdometerIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Odometer"
    static let description = IntentDescription("Gets the odometer reading from a vehicle's latest fuel log.")
    static var supportedModes: IntentModes { .background }

    @Parameter(title: "Vehicle")
    var vehicle: VehicleEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Get the odometer for \(\.$vehicle)")
    }

    func perform() async throws -> some ReturnsValue<Measurement<UnitLength>> & ProvidesDialog {
        let fuelLog = try await TankfulIntentsEnvironment.latestFuelLog(for: vehicle)
        guard let storedOdometer = fuelLog.odometer else {
            throw TankfulIntentsError.noOdometer(vehicleName: vehicle.name)
        }
        let odometer = storedOdometer.converted(to: .miles)
        let reading = "\(odometer.value.formatted(.number.precision(.fractionLength(0)))) \(odometer.unit.symbol)"

        return .result(
            value: odometer,
            dialog: "The latest odometer reading for \(vehicle.name) is \(reading)."
        )
    }
}
//  GetOdometerIntent.swift
//  tankful
//
//  Created by Jake Walker on 17/09/2026.
//
