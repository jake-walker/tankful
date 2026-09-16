//
//  FuelHistoryView.swift
//  tankful
//
//  Created by Jake Walker on 15/09/2026.
//

import SwiftUI
import TankfulDomain

struct FuelHistoryView: View {
    @Environment(AppEnvironment.self) internal var env

    @State internal var logs: [CalculatedFuelLog] = []
    @State internal var vehicle: Vehicle?

    var body: some View {
        List(logs) { log in
            NavigationLink(value: AppRoute.fuelLog(log.id)) {
                FuelLogItem(fuelLog: log)
            }
        }
        .navigationTitle(vehicle?.displayName ?? "Fuel History")
        .task {
            await load()
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

#if !os(Android)
    #Preview {
        NavigationView {
            FuelHistoryView()
                .environment(AppEnvironment.preview())
        }
    }
#endif
