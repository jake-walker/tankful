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

    let websiteUrl = URL(string: "https://tankful.jakewalker.xyz")!
    let privacyUrl = URL(string: "https://tankful.jakewalker.xyz/privacy")!
    let repoUrl = URL(string: "https://github.com/jake-walker/tankful")!

    @State var selectingCurrency: Bool = false

    private var versionText: String? {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        else {
            return nil
        }

        return String(
            format: NSLocalizedString(
                "Version %@ (%@)",
                comment: "Settings version number text; arguments are version and build numbers"
            ),
            version,
            buildNumber
        )
    }

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
                    NavigationLink(destination: EmptyView()) {
                        LabeledContent {
                            Text(env.currency.name)
                        } label: {
                            Text("Currency")
                        }
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Text("Units")
            } footer: {
                Text(
                    "Changing distance, volume and fuel economy units only affects how values are shown and entered in the app - not the units stored in the sync backend (if enabled). The currency setting applies only to future entries."
                )
            }

            Section {
                NavigationLink(value: AppRoute.syncSettings) {
                    Text("Sync Settings")
                }
            }

            Section {
                Link(destination: websiteUrl) {
                    NavigationLink(destination: EmptyView()) {
                        Text("Website")
                    }
                }
                .buttonStyle(.plain)

                Link(destination: privacyUrl) {
                    NavigationLink(destination: EmptyView()) {
                        Text("Privacy Policy")
                    }
                }
                .buttonStyle(.plain)

                Link(destination: repoUrl) {
                    NavigationLink(destination: EmptyView()) {
                        VStack(alignment: .leading) {
                            Text("View on GitHub")
                            Text("Licensed under GNU GPL v3.0")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Text("About")
            } footer: {
                if let versionText {
                    Text(versionText)
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $selectingCurrency) {
            NavigationStack {
                CurrencyPickerSheet(onSelect: { currency in
                    if let descriptor = CurrencyMint(defaultCurrency: USD.self).make(
                        identifier: .alphaCode(currency)
                    )?.descriptor {
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
