//
//  FuelHistoryView.swift
//  tankful
//
//  Created by Jake Walker on 15/09/2026.
//

import SwiftUI
import TankfulDomain

struct FuelHistoryView: View {
    @Environment(AppEnvironment.self) var env

    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        private var isCompact: Bool {
            horizontalSizeClass == .compact
        }
    #else
        private let isCompact = false
    #endif

    @State var logs: [CalculatedFuelLog] = []
    @State var vehicle: Vehicle?

    @State var selection: FuelLog.ID?

    var body: some View {
        Group {
            #if os(Android)
                List(logs) { log in
                    NavigationLink(value: AppRoute.fuelLog(log.id)) {
                        FuelLogItem(fuelLog: log)
                    }
                }
            #else
                Table(logs, selection: $selection) {
                    TableColumn("Date") { log in
                        Group {
                            if !isCompact {
                                Text(log.log.date.formatted(date: .abbreviated, time: .omitted))
                            } else {
                                FuelLogItem(fuelLog: log)
                            }
                        }
                        .fuelLogEntity(id: log.id)
                    }
                    TableColumn("Volume") { log in
                        if let volume = log.log.volume {
                            Text(env.formatter.volume(volume).description)
                        } else {
                            Text("-")
                                .foregroundStyle(.secondary)
                        }
                    }
                    TableColumn("Cost") { log in
                        Text(log.log.cost.localizedString())
                    }
                    TableColumn("Distance") { log in
                        if let distance = log.distance {
                            Text(env.formatter.distance(distance).description)
                        } else {
                            Text("-")
                                .foregroundStyle(.secondary)
                        }
                    }
                    TableColumn("Fuel Economy") { log in
                        if let economy = log.economy {
                            Text(env.formatter.economy(economy).description)
                        } else {
                            Text("-")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onChange(of: selection) { _, id in
                    guard let id else {
                        return
                    }

                    env.router.push(.fuelLog(id))

                    selection = nil
                }
            #endif
        }
        .navigationTitle(vehicle?.displayName ?? NSLocalizedString("Fuel History", comment: "Fuel history screen title"))
        .task {
            await load()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: AppRoute.addFuelLog) {
                    Label("Add Fill-Up", systemImage: "plus")
                }
            }
        }
    }

    private func load() async {
        guard let id = env.currentVehicleID else {
            vehicle = nil
            logs = []
            return
        }

        guard let loadedVehicle = try? await env.vehicleRepository.vehicle(id: id) else {
            vehicle = nil
            logs = []
            return
        }

        vehicle = loadedVehicle
        logs = (try? await env.fuelLogRepository.fuelLogs(for: loadedVehicle.id).calculated()) ?? []
    }
}

#if !os(Android) && DEBUG
    #Preview {
        NavigationStack {
            FuelHistoryView()
                .environment(AppEnvironment.preview())
        }
    }
#endif
