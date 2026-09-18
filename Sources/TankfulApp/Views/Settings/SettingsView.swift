//
//  SettingsView.swift
//  tankful
//
//  Created by Jake Walker on 15/09/2026.
//

import SwiftUI
import TankfulSync

struct SettingsView: View {
    @Environment(AppEnvironment.self) var env

    var body: some View {
        @Bindable var env = env

        Form {
            Section {
                Picker("Distance", selection: $env.distanceUnit) {
                    ForEach(DistanceUnit.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }

                Picker("Volume", selection: $env.volumeUnit) {
                    ForEach(VolumeUnit.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }

                Picker("Fuel Economy", selection: $env.fuelEconomyUnit) {
                    ForEach(FuelEconomyUnit.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }

                LabeledContent {
                    Text(env.currency.name)
                } label: {
                    Text("Currency")
                }
            } header: {
                Text("Units")
            } footer: {
                Text("Currency is determined by your device's region settings and is used for new fill-ups.")
            }

            Section {
                NavigationLink(value: AppRoute.syncSettings) {
                    Text("Sync Settings")
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#if !os(Android)
    #Preview {
        NavigationStack {
            SettingsView()
                .environment(AppEnvironment.preview())
        }
    }
#endif
