//
//  FuelPriceChartView.swift
//  tankful
//
//  Created by Jake Walker on 10/11/2026.
//

import Currency
import SwiftUI
import TankfulDomain

#if canImport(Charts)
    import Charts
#endif

struct FuelPriceChartView: View {
    @Environment(AppEnvironment.self) var env

    let fuelLogs: ArraySlice<CalculatedFuelLog>

    #if canImport(Charts)
        private var filteredLogs: [FuelLog] {
            fuelLogs
                .map { $0.log }
                .filter { $0.unitCost != nil && $0.unitCost?.descriptor == env.currency }
                .reversed()
        }

        private func formatValue(_ value: Decimal) -> String? {
            guard let currencyValue = CurrencyMint.standard.make(
                identifier: .alphaCode(env.currency.alphabeticCode),
                exactAmount: value
            ) else {
                return nil
            }

            return "\(currencyValue.localizedString())/\(env.volumeUnit.unit.symbol)"
        }

        var body: some View {
            Chart(filteredLogs) { log in
                if let unitCost = log.unitCost {
                    LineMark(
                        x: .value(
                            NSLocalizedString(
                                "Date", comment: "Fuel price chart date axis label"
                            ), log.date
                        ),
                        y: .value(
                            NSLocalizedString(
                                "Unit Price", comment: "Fuel price chart value label"
                            ),
                            unitCost.exactAmount
                        )
                    )
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    AxisGridLine()

                    AxisValueLabel {
                        if let v = value.as(Decimal.self),
                           let formatted = formatValue(v)
                        {
                            Text(formatted)
                        }
                    }
                }
            }
            .frame(minHeight: 120, idealHeight: 160, maxHeight: 280)
        }
    #else
        var body: some View {
            EmptyView()
        }
    #endif
}
