//
//  FuelLogItem.swift
//  tankful
//
//  Created by Jake Walker on 15/09/2026.
//

import Currency
import SwiftUI
import TankfulDomain

struct FuelLogItem: View {
    @Environment(AppEnvironment.self) var env

    let fuelLog: CalculatedFuelLog
    let showChevron: Bool

    init(fuelLog: CalculatedFuelLog) {
        self.fuelLog = fuelLog
        showChevron = false
    }

    init(fuelLog: CalculatedFuelLog, showChevron: Bool) {
        self.fuelLog = fuelLog
        self.showChevron = showChevron
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(fuelLog.log.date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.headline)
                        .fontWeight(.medium)

                    Spacer()

                    if let economy = fuelLog.economy {
                        let formatted = env.formatter.economy(economy)

                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(formatted.value)
                                .font(.headline)
                                .fontWeight(.semibold)
                            #if !os(Android)
                                .monospacedDigit()
                            #endif

                            Text(formatted.symbol)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else if !fuelLog.log.filled {
                        Text("Partial fill")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(alignment: .firstTextBaseline) {
                    if let volume = fuelLog.log.volume {
                        Text("\(fuelLog.log.cost.localizedString()) · \(env.formatter.volume(volume).description)")
                    } else {
                        Text(fuelLog.log.cost.description)
                    }

                    Spacer()

                    if let distance = fuelLog.distance {
                        Text(env.formatter.distance(distance).description)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                #if !os(Android)
                    .monospacedDigit()
                #endif
            }

            if showChevron {
                Image(systemName: "chevron.right")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if !os(Android) && DEBUG
    #Preview {
        FuelLogItem(
            fuelLog: CalculatedFuelLog(
                log: FuelLog(
                    id: UUID(),
                    vehicleID: Vehicle.ID(),
                    date: .now,
                    odometer: Measurement(value: 59226, unit: .miles),
                    volume: Measurement(value: 41.5, unit: .liters),
                    cost: GBP(minorUnits: 5723),
                    filled: true,
                    missedLast: false,
                    notes: nil
                ),
                distance: Measurement(value: 384, unit: .miles)
            ),
            showChevron: true
        )
        .environment(AppEnvironment.preview())
    }
#endif
