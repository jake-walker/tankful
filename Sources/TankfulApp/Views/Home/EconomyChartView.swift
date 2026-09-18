//
//  EconomyChartView.swift
//  tankful
//
//  Created by Jake Walker on 18/09/2026.
//

import SwiftUI
import TankfulDomain

#if canImport(Charts)
    import Charts
#endif

struct EconomyChartView: View {
    let fuelLogs: [CalculatedFuelLog]
    let unit: FuelEconomyUnit

    #if canImport(Charts)
        private var filteredLogs: [CalculatedFuelLog] {
            fuelLogs
                .filter { $0.economy != nil }
                .reversed()
        }

        var body: some View {
            Chart(filteredLogs) { log in
                if let economy = log.economy {
                    LineMark(
                        x: .value(
                            NSLocalizedString(
                                "Date", comment: "Fuel economy chart date axis label"
                            ), log.log.date
                        ),
                        y: .value(
                            NSLocalizedString(
                                "Fuel Economy", comment: "Fuel economy chart value label"
                            ),
                            economy.converted(to: unit.unit).value
                        )
                    )
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    AxisGridLine()

                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v)) \(unit.unit.symbol)")
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
