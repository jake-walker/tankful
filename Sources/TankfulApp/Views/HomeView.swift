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

    private var chartFuelLogs: [CalculatedFuelLog] {
        return
            fuelLogs
                .filter { $0.economy != nil }
                .reversed()
    }

    private var lastCostPerMile: (any CurrencyValue)? {
        guard !fuelLogs.isEmpty else {
            return nil
        }

        return fuelLogs[0].costPerDistance(unit: env.distanceUnit.unit)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if isLoading && vehicles.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vehicles.isEmpty {
                    noVehiclesView
                } else if fuelLogs.isEmpty {
                    noFuelLogsView
                } else {
                    Group {
                        VStack(spacing: 18) {
                            chart

                            summaryMetrics
                        }
                        .cardStyle()

                        recentFillUpsSection
                            .cardStyle(padding: false)
                    }
                    .vehicleEntity(id: vehicle?.id)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
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
                                    Label(
                                        vehicle.displayName,
                                        systemImage: env.currentVehicleID == vehicle.id
                                            ? "checkmark.circle" : "circle"
                                    )
                                }
                            }
                        }
                    }

                    Section {
                        if let vehicleID = env.currentVehicleID {
                            NavigationLink(value: AppRoute.vehicle(vehicleID)) {
                                Label("Vehicle Settings", systemImage: "car")
                            }
                        }

                        Button("Add Vehicle", systemImage: "plus") {
                            env.router.push(AppRoute.addVehicle)
                        }
                    }

                    Section {
                        NavigationLink(value: AppRoute.settings) {
                            Label("Settings", systemImage: "gear")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .task(id: env.vehicleChangeVersion) {
            await loadVehicle()
        }
        .refreshable {
            try? await env.syncNow()
            await loadVehicle()
        }
    }

    private var summaryMetrics: some View {
        HStack(spacing: 8) {
            if let economy = fuelLogs.averageFuelEconomy {
                metricView(
                    value: env.formatter.economy(economy).description,
                    label: NSLocalizedString(
                        "Avg. Economy", comment: "Average fuel economy metric label"
                    )
                )

                Divider()
            }

            if let averageCostPerDistance = fuelLogs.averageCostPerDistance(
                unit: env.distanceUnit.unit
            ) {
                metricView(
                    value:
                    "\(averageCostPerDistance.localizedString())/\(env.distanceUnit.unit.symbol)",
                    label: env.distanceUnit.costPerDisplayName
                )

                Divider()
            }

            metricView(
                value: env.formatter.distance(fuelLogs.totalDistance).description,
                label: NSLocalizedString("Distance", comment: "Total distance metric label")
            )
        }
    }

    private var noVehiclesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "car")
                .font(.largeTitle)

            Text("Add Your First Vehicle")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add a vehicle before recording fill-ups and tracking fuel economy.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Add Vehicle", systemImage: "plus") {
                env.router.push(AppRoute.addVehicle)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var noFuelLogsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "fuelpump")
                .font(.largeTitle)

            Text("No Recent Fill-Ups")
                .font(.title2)
                .fontWeight(.semibold)

            Text("No fill-ups have been recorded for this vehicle in the last six months.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Add Fill-Up", systemImage: "plus") {
                env.router.push(AppRoute.addFuelLog)
            }
            .buttonStyle(.borderedProminent)

            NavigationLink("Show Full History", value: AppRoute.fuelLogs)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func metricView(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .semibold))
            #if !os(Android)
                .monospacedDigit()
            #endif
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recentFillUpsSection: some View {
        VStack {
            HStack {
                Text("Recent fill-ups")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                NavigationLink(value: AppRoute.addFuelLog) {
                    Label("Add Fill-Up", systemImage: "plus")
                }
                .labelStyle(.iconOnly)
            }
            .padding([.horizontal, .top])

            ForEach(fuelLogs.prefix(recentFillUpLimit)) { log in
                Divider()

                NavigationLink(value: AppRoute.fuelLog(log.log.id)) {
                    FuelLogItem(fuelLog: log, showChevron: true)
                        .fuelLogEntity(id: log.id)
                        .padding(.horizontal)
                    #if !os(Android) && !os(macOS)
                        .foregroundStyle(Color(uiColor: .label))
                    #endif
                }
            }

            NavigationLink(value: AppRoute.fuelLogs) {
                Label("Show More", systemImage: "chevron.right")
            }
            .padding(.top, 32)
            .padding(.bottom)
        }
    }

    private var chart: some View {
        #if canImport(Charts)
            Chart(chartFuelLogs) { log in
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
                            economy.converted(to: env.fuelEconomyUnit.unit).value
                        )
                    )
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()

                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v)) \(env.fuelEconomyUnit.unit.symbol)")
                        }
                    }
                }
            }
            .frame(minHeight: 120, idealHeight: 160, maxHeight: 280)
        #else
            EmptyView()
        #endif
    }

    private func fillUpValueText(_ value: String?) -> some View {
        Text(value ?? "-")
            .frame(maxWidth: .infinity)
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
