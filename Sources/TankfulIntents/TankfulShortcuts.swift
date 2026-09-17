//
//  TankfulShortcuts.swift
//  tankful
//
//  Created by Jake Walker on 17/09/2026.
//

import AppIntents

@available(anyAppleOS 26.0, *)
struct TankfulShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddFuelLogIntent(),
            phrases: [
                "Add fuel in \(.applicationName)",
                "Log a fill-up in \(.applicationName)",
                "Add a fill-up to \(.applicationName)"
            ],
            shortTitle: "Add Fuel",
            systemImageName: "fuelpump.fill"
        )
        AppShortcut(
            intent: GetFuelEconomyIntent(),
            phrases: [
                "Get fuel economy in \(.applicationName)",
                "What's my fuel economy in \(.applicationName)"
            ],
            shortTitle: "Fuel Economy",
            systemImageName: "gauge.with.dots.needle.50percent"
        )
        AppShortcut(
            intent: GetOdometerIntent(),
            phrases: [
                "Get my odometer in \(.applicationName)",
                "What's my mileage in \(.applicationName)"
            ],
            shortTitle: "Get Odometer",
            systemImageName: "gauge.with.dots.needle.bottom.50percent"
        )
        AppShortcut(
            intent: GetLastFuelLogIntent(),
            phrases: [
                "Get my latest fill-up in \(.applicationName)",
                "Show my last fill-up in \(.applicationName)"
            ],
            shortTitle: "Latest Fill-Up",
            systemImageName: "fuelpump"
        )
    }
}
