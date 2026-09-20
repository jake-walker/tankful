//
//  SettingsView.swift
//  tankful
//
//  Created by Jake Walker on 15/09/2026.
//

import Currency
import SwiftUI
import TankfulSync

struct SettingsView: View {
    @Environment(AppEnvironment.self) var env

    @State var selectingCurrency: Bool = false

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

                Button(action: {
                    selectingCurrency.toggle()
                }) {
                    LabeledContent {
                        Text(env.currency.name)
                    } label: {
                        Text("Currency")
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Text("Units")
            } footer: {
                Text("Changing distance, volume and fuel economy units only affects how values are shown and entered in the app - not the units stored in the sync backend (if enabled). The currency setting applies only to future entries.")
            }

            Section {
                NavigationLink(value: AppRoute.syncSettings) {
                    Text("Sync Settings")
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $selectingCurrency) {
            NavigationStack {
                CurrencyPickerSheet(onSelect: { currency in
                    if let descriptor = CurrencyMint(defaultCurrency: USD.self).make(identifier: .alphaCode(currency))?.descriptor {
                        env.currency = descriptor
                    }
                })
            }
            .presentationDetents([.medium, .large])
        }
    }
}

#if !os(Android) && DEBUG
    #Preview {
        NavigationStack {
            SettingsView()
                .environment(AppEnvironment.preview())
        }
    }
#endif
