//
//  StatsCardView.swift
//  tankful
//
//  Created by Jake Walker on 18/09/2026.
//

import SwiftUI
import TankfulDomain

struct StatsCardView: View {
    @Environment(AppEnvironment.self) var env

    let fuelLogs: [CalculatedFuelLog]

    private var metrics: [Metric] {
        var items: [Metric] = []

        if let economy = fuelLogs.averageFuelEconomy {
            items.append(Metric(
                label: NSLocalizedString(
                    "Avg. Economy",
                    comment: "Average fuel economy metric label"
                ),
                value: env.formatter.economy(economy)
            ))
        }

        if let cost = fuelLogs.averageCostPerDistance(unit: env.distanceUnit.unit) {
            items.append(Metric(
                label: env.distanceUnit.costPerDisplayName,
                value: FormattedMeasurement(value: cost.localizedString(), symbol: "/\(env.distanceUnit.unit.symbol)")
            ))
        }

        items.append(Metric(
            label: NSLocalizedString(
                "Distance",
                comment: "Total distance metric label"
            ),
            value: env.formatter.distance(fuelLogs.totalDistance, fractionLength: 0)
        ))

        return items
    }

    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 8) {
                ForEach(Array(metrics.enumerated()), id: \.offset) { i, metric in
                    if i != 0 {
                        Divider()
                    }

                    metricView(metric)
                }
            }

            EconomyChartView(fuelLogs: fuelLogs, unit: env.fuelEconomyUnit)
        }
        .cardStyle()
    }

    private func metricView(_ metric: Metric) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(metric.label)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(metric.value.value)
                    .font(.system(size: 24, weight: .semibold))
                #if !os(Android)
                    .monospacedDigit()
                #endif
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(metric.value.symbol)
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct Metric {
    let label: String
    let value: FormattedMeasurement
}
