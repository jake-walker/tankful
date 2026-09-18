//
//  RecentLogsView.swift
//  tankful
//
//  Created by Jake Walker on 18/09/2026.
//

import SwiftUI
import TankfulDomain

struct RecentLogsView: View {
    let fuelLogs: ArraySlice<CalculatedFuelLog>

    var body: some View {
        VStack(spacing: 16) {
            NavigationLink(value: AppRoute.fuelLogs) {
                HStack {
                    Text("Recent Fill-Ups")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Spacer()

                    AppIcon(symbol: .forward)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            ForEach(fuelLogs) { log in
                NavigationLink(value: AppRoute.fuelLog(log.log.id)) {
                    FuelLogItem(fuelLog: log, showChevron: true)
                        .fuelLogEntity(id: log.id)
                }
                .buttonStyle(.plain)
            }
        }
        .cardStyle()
    }
}
