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
    @Environment(AppEnvironment.self) internal var env
    
    let recentCount: Int = 5
    
    @State internal var vehicles: [Vehicle] = []
    @State internal var vehicle: Vehicle?
    @State internal var fuelLogs: [CalculatedFuelLog] = []
    @State internal var isLoading: Bool = true
    
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
        .navigationTitle(vehicle?.displayName ?? NSLocalizedString("Vehicle", comment: "Fallback vehicle screen title"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if vehicles.count > 1 {
                        Section {
                            ForEach(vehicles) { vehicle in
                                Button {
                                    selectVehicle(vehicle)
                                } label: {
                                    Label(vehicle.displayName, systemImage: env.currentVehicleID == vehicle.id ? "checkmark.circle" : "circle")
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
            if let economy = fuelLogs.suffix(recentCount).averageFuelEconomy {
                metricView(
                    value: env.formatter.economy(economy).description,
                    label: NSLocalizedString("Avg. Economy", comment: "Average fuel economy metric label")
                )
                
                Divider()
            }
            
            if let averageCostPerDistance = fuelLogs.suffix(recentCount).averageCostPerDistance(unit: env.distanceUnit.unit) {
                metricView(value: "\(averageCostPerDistance.localizedString())/\(env.distanceUnit.unit.symbol)", label: env.distanceUnit.costPerDisplayName)
                
                Divider()
            }
            
            metricView(
                value: env.formatter.distance(fuelLogs.suffix(recentCount).totalDistance).description,
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

            Text("No Fill-Ups Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add the first fill-up for this vehicle to start tracking its fuel usage.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Add Fill-Up", systemImage: "plus") {
                env.router.push(AppRoute.addFuelLog)
            }
            .buttonStyle(.borderedProminent)
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
            
            ForEach(fuelLogs.prefix(recentCount)) { log in
                Divider()
                
                NavigationLink(value: AppRoute.fuelLog(log.log.id)) {
                    FuelLogItem(fuelLog: log, showChevron: true)
                        .fuelLogEntity(id: log.id)
                        .padding(.horizontal)
#if !os(Android)
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
        Chart(fuelLogs.reversed().dropFirst()) { log in
            LineMark(
                x: .value(NSLocalizedString("Date", comment: "Fuel economy chart date axis label"), log.log.date),
                y: .value(
                    NSLocalizedString("Fuel Economy", comment: "Fuel economy chart value label"),
                    log.economy?.converted(to: env.fuelEconomyUnit.unit).value ?? 0
                )
            )
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
        fuelLogs = (try? await env.fuelLogRepository.fuelLogs(for: loadedVehicle.id).calculated()) ?? []
    }

    private func selectVehicle(_ selectedVehicle: Vehicle) {
        vehicle = selectedVehicle
        fuelLogs = []
        env.selectVehicle(id: selectedVehicle.id)
    }
}

#if !os(Android)
#Preview {
    NavigationView {
        HomeView()
            .environment(AppEnvironment.preview())
    }
}
#endif
