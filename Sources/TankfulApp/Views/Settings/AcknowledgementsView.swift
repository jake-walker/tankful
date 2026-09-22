//
//  AcknowledgementsView.swift
//  tankful
//
//  Created by Jake Walker on 22/09/2026.
//

import SwiftUI

struct AcknowledgementsView: View {
    @State var selectedLicense: LicensesPlugin.License?

    var body: some View {
        List {
            Section {
                ForEach(LicensesPlugin.licenses) { license in
                    Button(action: {
                        selectedLicense = license
                    }) {
                        Text(license.name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("This app is built with the help of the following open source libraries.")
                    .font(.caption)
            }
        }
        .navigationTitle("Acknowledgements")
        .sheet(item: $selectedLicense) { license in
            NavigationStack {
                ScrollView {
                    Text(license.licenseText ?? "No license found")
                        .font(.caption)
                        .monospaced()
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .navigationTitle(license.name)
            }
        }
    }
}

#if !os(Android) && DEBUG
    #Preview {
        NavigationStack {
            AcknowledgementsView()
        }
    }
#endif
