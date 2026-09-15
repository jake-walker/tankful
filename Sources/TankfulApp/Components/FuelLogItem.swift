//
//  FuelLogItem.swift
//  tankful
//
//  Created by Jake Walker on 15/09/2026.
//

import SwiftUI
import TankfulDomain
import Currency

struct FuelLogItem: View {
    @Environment(AppEnvironment.self) internal var env
    
    let fuelLog: CalculatedFuelLog
    let showChevron: Bool
    
    init(fuelLog: CalculatedFuelLog) {
        self.fuelLog = fuelLog
        self.showChevron = false
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
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(economy.milesPerImperialGallon.formatted(.number.precision(.fractionLength(1))))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                            
                            Text("mpg")
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
                        Text("\(fuelLog.log.cost.localizedString()) · \(env.formatter.volume(volume))")
                    } else {
                        Text(fuelLog.log.cost.description)
                    }
                    
                    Spacer()
                    
                    if let distance = fuelLog.distance {
                        Text(env.formatter.distance(distance))
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            }
            
            if showChevron {
                Image(systemName: "chevron.right")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

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
