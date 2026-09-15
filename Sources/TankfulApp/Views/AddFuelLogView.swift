//
//  AddFuelLogView.swift
//  tankful
//
//  Created by Jake Walker on 15/09/2026.
//

import SwiftUI
import TankfulDomain
import Currency

struct AddFuelLogView: View {
    @Environment(AppEnvironment.self) internal var env
    
    @State internal var vehicles: [Vehicle] = []
    
    @State internal var vehicleID: Vehicle.ID?
    @State internal var date: Date = .now
    @State internal var odometer: String = ""
    @State internal var volume: String = ""
    @State internal var cost: String = ""
    @State internal var filled: Bool = true
    @State internal var missedLast: Bool = false
    @State internal var notes: String = ""
    @State internal var isSaving: Bool = false
    @State internal var isShowingError: Bool = false
    @State internal var errorMessage: String = ""
    
    var body: some View {
        Form {
            if vehicles.count > 1 {
                Picker("Vehicle", selection: $vehicleID) {
                    ForEach(vehicles) { vehicle in
                        Text("\(vehicle.displayName)")
                            .tag(vehicle.id)
                    }
                }
            }
            
            DatePicker("Date", selection: $date, displayedComponents: [.date])
            
            LabeledContent {
                TextField("Odometer", text: $odometer)
                    .multilineTextAlignment(.trailing)
            } label: {
                Text("Odometer")
            }
                
            TextField("Volume of Fuel", text: $volume)
            TextField("Total Cost", text: $cost)
            Toggle("Filled Tank", isOn: $filled)
            Toggle("Missed Last", isOn: $missedLast)
            TextField("Notes", text: $notes)
        }
        .navigationTitle("Add Fuel Log")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if #available(iOS 26.0, *) {
                    Button("Save", systemImage: "checkmark", role: .confirm) {
                        Task { await save() }
                    }
                    .disabled(isSaving || !isFormValid)
                } else {
                    Button("Save", systemImage: "checkmark") {
                        Task { await save() }
                    }
                    .disabled(isSaving || !isFormValid)
                }
            }
        }
        .task {
            await load()
        }
        .alert("Unable to Save Fill-Up", isPresented: $isShowingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private var isFormValid: Bool {
        guard let odometerValue = Double(odometer),
              let volumeValue = Double(volume),
              let costValue = Decimal(string: cost) else {
            return false
        }

        return vehicleID != nil
            && odometerValue >= 0
            && volumeValue > 0
            && costValue >= .zero
    }
    
    private func load() async {
        vehicleID = env.currentVehicleID
        
        vehicles = (try? await env.vehicleRepository.vehicles()) ?? []
    }

    private func save() async {
        guard !isSaving,
              let vehicleID,
              let odometerValue = Double(odometer),
              let volumeValue = Double(volume),
              let costValue = Decimal(string: cost),
              odometerValue >= 0,
              volumeValue > 0,
              costValue >= .zero else {
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let existingLogs = try await env.fuelLogRepository.fuelLogs(for: vehicleID)
            let fuelLog = FuelLog(
                id: FuelLog.ID(),
                vehicleID: vehicleID,
                date: date,
                odometer: Measurement(value: odometerValue, unit: env.distanceUnit.unit),
                volume: Measurement(value: volumeValue, unit: env.volumeUnit.unit),
                cost: GBP(exactAmount: costValue),
                filled: filled,
                missedLast: existingLogs.isEmpty || missedLast,
                notes: notes.isEmpty ? nil : notes
            )

            try await env.fuelLogRepository.save(fuelLog)
            env.selectVehicle(id: vehicleID)
            env.router.pop()
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }
}

#Preview {
    NavigationView {
        AddFuelLogView()
            .environment(AppEnvironment.preview())
    }
}
