import AppIntents

@available(anyAppleOS 26.0, *)
struct OpenFuelLogIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Fill-Up"
    static let description = IntentDescription("Opens a fill-up in Tankful.")
    static var supportedModes: IntentModes {
        .foreground
    }

    @Parameter(title: "Fill-Up")
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
