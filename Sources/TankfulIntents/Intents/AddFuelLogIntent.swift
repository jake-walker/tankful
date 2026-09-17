//
//  AddFuelLogIntent.swift
//  tankful
//
//  Created by Jake Walker on 17/09/2026.
//

import AppIntents

@available(anyAppleOS 26.0, *)
struct AddFuelLogIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Fill-Up"
    static let description = IntentDescription("Adds a fill-up to a vehicle in Tankful.")
    static var supportedModes: IntentModes { .background }

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$volume) for \(\.$vehicle)") {
            \.$cost
            \.$odometer
            \.$date
        }
    }
    
    @Parameter(title: "Vehicle")
    var vehicle: VehicleEntity
    
    @Parameter(title: "Volume")
    var volume: Measurement<UnitVolume>
    
    @Parameter(title: "Cost")
    var cost: Double
    
    @Parameter(title: "Odometer")
    var odometer: Measurement<UnitLength>
    
    @Parameter(title: "Date")
    var date: Date?
    
    func perform() async throws -> some ReturnsValue<FuelLogEntity> & ProvidesDialog {
        let fuelLog = try await TankfulIntentsEnvironment.addFuelLog(
            vehicleID: vehicle.id,
            volume: volume,
            cost: Decimal(cost),
            odometer: odometer,
            date: date ?? .now
        )

        return .result(
            value: fuelLog,
            dialog: "Added a fill-up for \(vehicle.name)."
        )
    }
}
