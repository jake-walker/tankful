import AppIntents

@available(anyAppleOS 26.0, *)
struct OpenFuelLogIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Fuel Log"
    static let description = IntentDescription("Opens a fuel log in Tankful.")
    static var supportedModes: IntentModes { .foreground }

    @Parameter(title: "Fuel Log")
    var target: FuelLogEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$target)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        try TankfulIntentsEnvironment.openFuelLog(id: target.id)
        return .result()
    }
}
//  OpenFuelLogIntent.swift
//  tankful
//
//  Created by Jake Walker on 17/09/2026.
//
