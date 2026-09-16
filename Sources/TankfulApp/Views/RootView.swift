//
//  RootView.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) internal var env
    
    var body: some View {
        @Bindable var router = env.router
        
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: AppRoute.self, destination: { destination in
                    switch destination {
                    case let .fuelLog(id):
                        FuelLogDetailView(fuelLogID: id)
                    case let .vehicle(id):
                        VehicleView(vehicleID: id)
                    case .settings:
                        SettingsView()
                    case .syncSettings:
                        SyncSettingsView()
                    case .addVehicle:
                        VehicleView()
                    case .fuelLogs:
                        FuelHistoryView()
                    case .addFuelLog:
                        AddFuelLogView()
                    }
                })
        }
    }
}

#if !os(Android)
#Preview {
    RootView()
        .environment(AppEnvironment.preview())
}
#endif
