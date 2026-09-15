//
//  SettingsView.swift
//  tankful
//
//  Created by Jake Walker on 15/09/2026.
//

import SwiftUI
import TankfulSync

struct SettingsView: View {
    @Environment(AppEnvironment.self) internal var env

    var body: some View {
        @Bindable var env = env

        Form {
            Section("Units") {
                Picker("Distance", selection: $env.distanceUnit) {
                    Text("Miles").tag(DistanceUnit.miles)
                    Text("Kilometres").tag(DistanceUnit.kilometres)
                }

                Picker("Volume", selection: $env.volumeUnit) {
                    Text("Litres").tag(VolumeUnit.litres)
                    Text("Imperial Gallons").tag(VolumeUnit.imperialGallons)
                    Text("US Gallons").tag(VolumeUnit.usGallons)
                }
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

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AppEnvironment.preview())
    }
}
