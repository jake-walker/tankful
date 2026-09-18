//
//  AddFuelLogView.swift
//  tankful
//
//  Created by Jake Walker on 15/09/2026.
//

import Currency
import SwiftUI
import TankfulDomain

struct AddFuelLogView: View {
    @Environment(AppEnvironment.self) var env

    @State var vehicles: [Vehicle] = []

    @State var vehicleID: Vehicle.ID?
    @State var date: Date = .now
    @State var odometer: Int?
    @State var volume: Double?
    @State var cost: Decimal?
    @State var filled: Bool = true
    @State var missedLast: Bool = false
    @State var notes: String = ""
    @State var isSaving: Bool = false
    @State var isShowingError: Bool = false
    @State var errorMessage: String = ""

    private var unitCost: (any CurrencyValue)? {
        guard let volume,
              let cost,
              volume > 0
        else {
            return nil
        }

        return CurrencyMint.standard.make(
            identifier: .alphaCode(env.currency.alphabeticCode),
            exactAmount: cost / Decimal(volume)
        )
    }

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = env.currency.alphabeticCode

        return formatter.currencySymbol ?? env.currency.alphabeticCode
    }

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

            DatePicker("Date", selection: $date)

            LabeledContent {
                TextField(
                    "-",
                    value: $odometer,
                    format: .number.grouping(.never)
                )
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
            } label: {
                Text("Odometer (\(env.distanceUnit.unit.symbol))")
            }

            LabeledContent {
                TextField(
                    "-",
                    value: $volume,
                    format: .number.grouping(.never)
                )
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            } label: {
                Text("Volume (\(env.volumeUnit.unit.symbol))")
            }

            LabeledContent {
                TextField(
                    "-",
                    value: $cost,
                    format: .number.grouping(.never)
                )
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            } label: {
                Text("Total Cost (\(currencySymbol))")
            }

            LabeledContent {
                if let unitCost {
                    Text("\(unitCost.localizedString())/\(env.volumeUnit.unit.symbol)")
                } else {
                    Text("-")
                }
            } label: {
                Text("Unit Cost")
            }

            Toggle("Filled Tank", isOn: $filled)
            Toggle("Missed Last", isOn: $missedLast)
            TextField("Notes", text: $notes)
        }
        .navigationTitle("Add Fill-Up")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if #available(anyAppleOS 26.0, *) {
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
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var isFormValid: Bool {
        guard let odometer,
              let volume,
              let cost
        else {
            return false
        }

        return vehicleID != nil
            && odometer >= 0
            && volume > 0
            && cost >= .zero
    }

    private func load() async {
        vehicleID = env.currentVehicleID

        vehicles = (try? await env.vehicleRepository.vehicles()) ?? []
    }

    private func save() async {
        guard !isSaving,
              let vehicleID,
              let odometer,
              let volume,
              let cost,
              odometer >= 0,
              volume > 0,
              cost >= .zero
        else {
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let existingLogs = try await env.fuelLogRepository.fuelLogs(for: vehicleID)

            let currencyValue = CurrencyMint.standard.make(
                identifier: .alphaCode(env.currency.alphabeticCode),
                exactAmount: cost
            ) ?? USD(exactAmount: cost)

            let fuelLog = FuelLog(
                id: FuelLog.ID(),
                vehicleID: vehicleID,
                date: date,
                odometer: Measurement(value: Double(odometer), unit: env.distanceUnit.unit),
                volume: Measurement(value: volume, unit: env.volumeUnit.unit),
                cost: currencyValue,
                filled: filled,
                missedLast: existingLogs.isEmpty || missedLast,
                notes: notes.isEmpty ? nil : notes
            )

            try await env.fuelLogController.create(fuelLog)
            env.selectVehicle(id: vehicleID)
            env.router.pop()
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }
}

#if !os(Android) && DEBUG
    #Preview {
        NavigationStack {
            AddFuelLogView()
                .environment(AppEnvironment.preview())
        }
    }
#endif
