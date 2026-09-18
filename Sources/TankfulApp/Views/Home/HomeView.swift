//
//  HomeView.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

import Currency
import SwiftUI
import TankfulDomain

#if canImport(Charts)
    import Charts
#endif

struct HomeView: View {
    @Environment(AppEnvironment.self) var env

    private let recentFillUpLimit = 5

    @State var vehicles: [Vehicle] = []
    @State var vehicle: Vehicle?
    @State var fuelLogs: [CalculatedFuelLog] = []
    @State var isLoading: Bool = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoading && vehicles.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vehicles.isEmpty {
                    noVehiclesView
                } else if fuelLogs.isEmpty {
                    noFuelLogsView
                } else {
                    Group {
                        StatsCardView(fuelLogs: fuelLogs)

                        RecentLogsView(fuelLogs: fuelLogs.prefix(recentFillUpLimit))
                    }
                    .vehicleEntity(id: vehicle?.id)
                }
            }
            .padding()
            #if os(Android)
                .padding(.bottom, vehicle == nil ? 0 : 80)
            #endif
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        #if os(Android)
        .overlay(alignment: .bottomTrailing) {
            if vehicle != nil {
                AndroidFab(
                    accessibilityLabel: NSLocalizedString("Add Fill-Up", comment: "Add fill-up button")
                ) {
                    env.router.push(AppRoute.addFuelLog)
                }
                .padding(16)
            }
        }
        #endif
        .navigationTitle(
            vehicle?.displayName
                ?? NSLocalizedString("Vehicle", comment: "Fallback vehicle screen title")
        )
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if vehicles.count > 1 {
                        Section {
                            ForEach(vehicles) { vehicle in
                                Button {
                                    selectVehicle(vehicle)
                                } label: {
                                    Label {
                                        Text(vehicle.displayName)
                                    } icon: {
                                        AppIcon(symbol: env.currentVehicleID == vehicle.id
                                            ? .selected : .unselected)
                                    }
                                }
                            }
                        }
                    }

                    Section {
                        if let vehicleID = env.currentVehicleID {
                            Button("Vehicle Settings", appIcon: .vehicle) {
                                env.router.push(AppRoute.vehicle(vehicleID))
                            }
                        }

                        Button("Add Vehicle", appIcon: .add) {
                            env.router.push(AppRoute.addVehicle)
                        }
                    }

                    Section {
                        Button("Settings", appIcon: .settings) {
                            env.router.push(AppRoute.settings)
                        }
                    }
                } label: {
                    AppIcon(symbol: .more)
                }
            }

            #if os(iOS)
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {
                        env.router.push(AppRoute.addFuelLog)
                    }) {
                        Label {
                            Text("Add Fill-Up")
                        } icon: {
                            Image("custom.fuelpump.badge.plus", bundle: .module)
                        }
                    }
                    .disabled(vehicle == nil)
                }
            #endif
        }
        .task(id: env.vehicleChangeVersion) {
            await loadVehicle()
        }
        .refreshable {
            try? await env.syncNow()
            await loadVehicle()
        }
    }

    private var noVehiclesView: some View {
        VStack(spacing: 16) {
            AppIcon(symbol: .vehicle, size: 32)
                .font(.largeTitle)

            Text("Add Your First Vehicle")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add a vehicle before recording fill-ups and tracking fuel economy.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Add Vehicle", appIcon: .add) {
                env.router.push(AppRoute.addVehicle)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var noFuelLogsView: some View {
        VStack(spacing: 16) {
            AppIcon(symbol: .fuel, size: 32)
                .font(.largeTitle)

            Text("No Recent Fill-Ups")
                .font(.title2)
                .fontWeight(.semibold)

            Text("No fill-ups have been recorded for this vehicle in the last six months.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Add Fill-Up", appIcon: .add) {
                env.router.push(AppRoute.addFuelLog)
            }
            .buttonStyle(.borderedProminent)

            NavigationLink("Show Full History", value: AppRoute.fuelLogs)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func loadVehicle() async {
        isLoading = true
        defer { isLoading = false }

        vehicles = (try? await env.vehicleRepository.vehicles()) ?? []

        guard !vehicles.isEmpty else {
            vehicle = nil
            fuelLogs = []
            return
        }

        let loadedVehicle = vehicles.first(where: { $0.id == env.currentVehicleID }) ?? vehicles[0]

        if env.currentVehicleID != loadedVehicle.id {
            env.currentVehicleID = loadedVehicle.id
        }

        vehicle = loadedVehicle

        let cutoffDate = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        fuelLogs =
            (try? await env.fuelLogRepository
                .fuelLogs(for: loadedVehicle.id, startingAt: cutoffDate)
                .calculated()) ?? []
    }

    private func selectVehicle(_ selectedVehicle: Vehicle) {
        vehicle = selectedVehicle
        fuelLogs = []
        env.selectVehicle(id: selectedVehicle.id)
    }
}

#if !os(Android) && DEBUG
    #Preview {
        NavigationStack {
            HomeView()
                .environment(AppEnvironment.preview())
        }
    }
#endif
