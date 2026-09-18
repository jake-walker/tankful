//
//  OpenVehicleIntent.swift
//  tankful
//
//  Created by OpenAI on 17/09/2026.
//

import AppIntents

@available(anyAppleOS 26.0, *)
struct OpenVehicleIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Vehicle"
    static let description = IntentDescription("Opens a vehicle in Tankful.")
    static var supportedModes: IntentModes {
        .foreground
    }

    @Parameter(title: "Vehicle")
    var target: VehicleEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$target)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        try TankfulIntentsEnvironment.openVehicle(id: target.id)
        return .result()
    }
}
