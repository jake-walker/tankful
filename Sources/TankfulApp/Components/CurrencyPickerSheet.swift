//
//  CurrencyPickerSheet.swift
//  tankful
//
//  Created by Jake Walker on 20/09/2026.
//

import Currency
import SwiftUI

struct CurrencyPickerSheet: View {
    @Environment(\.dismiss) var dismiss

    var onSelect: (String) -> Void

    @State var searchText: String = ""

    private var suggestedCurrency: CurrencyItem? {
        guard let currencyCode = Locale.current.currency?.identifier,
              let descriptor = CurrencyMint(defaultCurrency: USD.self).make(identifier: .alphaCode(currencyCode))?.descriptor
        else {
            return nil
        }

        return CurrencyItem(name: descriptor.name, code: descriptor.alphabeticCode)
    }

    private var filteredCurrencies: [CurrencyItem] {
        let currencies = CurrencyMint.supportedCurrencies
            .map { CurrencyItem(name: $0.name, code: $0.alphabeticCode) }
            .filter { !["XXX", "XTS"].contains($0.code) && suggestedCurrency?.code != $0.code }
            .sorted(by: { $0.code.localizedCaseInsensitiveCompare($1.code) == ComparisonResult.orderedAscending })

        guard !searchText.isEmpty else {
            return currencies
        }

        return currencies
            .filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.code.localizedCaseInsensitiveContains(searchText) }
    }

    private func currencyButton(_ currencyItem: CurrencyItem) -> some View {
        Button(action: {
            onSelect(currencyItem.code)
            dismiss()
        }) {
            VStack(alignment: .leading) {
                Text(currencyItem.code)
                Text(currencyItem.name)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    var body: some View {
        List {
            if let currency = suggestedCurrency {
                Section("Suggested") {
                    currencyButton(currency)
                }
            }

            Section {
                ForEach(filteredCurrencies) { currency in
                    currencyButton(currency)
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Currencies")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if #available(iOS 26.0, *) {
                    Button("Cancel", systemImage: "xmark", role: .close) {
                        dismiss()
                    }
                } else {
                    Button("Cancel", appIcon: .close) {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct CurrencyItem: Identifiable {
    let name: String
    let code: String

    var id: String {
        code
    }
}

#if !os(Android) && DEBUG
    #Preview {
        NavigationStack {
            CurrencyPickerSheet(onSelect: { _ in })
        }
    }
#endif
